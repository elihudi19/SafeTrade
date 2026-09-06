import random
import string
from datetime import timedelta
from decimal import Decimal

from django.db import transaction
from django.db.models import Sum
from django.utils import timezone
from rest_framework import viewsets, status, generics
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError as DRFValidationError
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from . import models, serializers, permissions as perms
from .services.fees import (
    calculate_and_record_pos_fee,
    calculate_and_record_marketplace_fee,
    credit_seller_sale_proceeds,
    NoFeeTierConfiguredError,
)
from .services.nida import verify_identity, NIDANotConfiguredError
from .services.sms import send_sms
from .services.costing import record_stock_intake
from .services.profit_loss import apply_receipt_costing, get_profit_loss_report


def log_action(actor, action_name, target_obj, metadata=None):
    models.AuditLog.objects.create(
        actor=actor,
        action=action_name,
        target_model=target_obj.__class__.__name__,
        target_id=target_obj.id,
        metadata_json=metadata or {},
    )


def _generate_otp_code():
    return "".join(random.choices(string.digits, k=6))


# =============================================================================
# OWNER REGISTRATION - NIDA + OTP (badala ya Leseni ya Biashara)
# =============================================================================

class OwnerRegistrationView(APIView):
    """
    POST /api/auth/register-owner/
    Hatua 1: Owner anatoa username, password, nida_number, phone_number,
    business_name. Mfumo unathibitisha phone_number dhidi ya nida_number
    kupitia NIDA API KABLA ya kutuma OTP - kama hailingani (mismatch),
    OTP HAITUMWI kabisa na mtumiaji anapata ujumbe wa alert.
    """
    permission_classes = [AllowAny]

    @transaction.atomic
    def post(self, request):
        serializer = serializers.OwnerRegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            is_match = verify_identity(data["nida_number"], data["phone_number"])
        except NIDANotConfiguredError as exc:
            return Response(
                {"error": "Uthibitishaji wa NIDA haujawekwa kwenye mfumo.",
                 "detail": str(exc)},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        if not is_match:
            # SHERIA MUHIMU: mismatch -> HAKUNA OTP inayotumwa, mtumiaji
            # anaarifiwa wazi kuhusu tofauti kati ya NIDA na namba ya simu.
            return Response(
                {"error": "mismatch",
                 "message": (
                     "Namba ya simu uliyotoa HAIENDANI na taarifa za NIDA "
                     "kwa NIDA namba uliyotoa. Tafadhali hakikisha "
                     "unatumia namba ya simu iliyosajiliwa rasmi kwenye "
                     "NIDA yako, kisha jaribu tena. Hatujatuma OTP yoyote."
                 )},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = models.User(
            username=data["username"],
            role=models.User.Role.OWNER,
            nida_number=data["nida_number"],
            phone_number=data["phone_number"],
            is_active=False,       # inawashwa baada ya OTP kuthibitishwa
            phone_verified=False,
        )
        user.set_password(data["password"])
        user.save()

        business = models.Business.objects.create(
            owner=user, name=data["business_name"],
            status=models.Business.Status.PENDING,
        )

        otp = models.OTPVerification.objects.create(
            user=user, phone_number=data["phone_number"],
            code=_generate_otp_code(),
            expires_at=timezone.now() + timedelta(minutes=10),
        )
        send_sms(
            data["phone_number"],
            f"SafeTrade: Namba yako ya uthibitisho (OTP) ni {otp.code}. "
            f"Inaisha muda dakika 10.",
        )
        log_action(user, "owner_registered_nida_verified", business,
                   {"nida_number": data["nida_number"]})

        return Response(
            {"message": "NIDA imethibitishwa. OTP imetumwa kwenye namba yako ya simu.",
             "user_id": str(user.id), "business_id": str(business.id)},
            status=status.HTTP_201_CREATED,
        )


class VerifyOTPView(APIView):
    """
    POST /api/auth/verify-otp/
    Hatua 2: Owner anaingiza OTP aliyopokea. Ikithibitika, akaunti
    inawashwa (is_active=True) na Business inakuwa Active moja kwa moja
    (badala ya kusubiri idhini ya leseni).
    """
    permission_classes = [AllowAny]

    @transaction.atomic
    def post(self, request):
        serializer = serializers.VerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone_number = serializer.validated_data["phone_number"]
        code = serializer.validated_data["code"]

        otp = models.OTPVerification.objects.filter(
            phone_number=phone_number, is_used=False
        ).order_by("-created_at").first()

        if not otp or not otp.is_valid():
            return Response({"error": "OTP haipo au muda wake umeisha. Omba OTP mpya."},
                             status=status.HTTP_400_BAD_REQUEST)

        if otp.code != code:
            otp.attempts += 1
            otp.save(update_fields=["attempts"])
            return Response({"error": "OTP siyo sahihi."}, status=status.HTTP_400_BAD_REQUEST)

        otp.is_used = True
        otp.save(update_fields=["is_used"])

        user = otp.user
        user.phone_verified = True
        user.is_active = True
        user.save(update_fields=["phone_verified", "is_active"])

        models.Business.objects.filter(owner=user).update(
            status=models.Business.Status.ACTIVE
        )
        log_action(user, "owner_phone_verified", user)

        return Response({"message": "Umethibitishwa. Akaunti yako sasa iko Active."})


class ResendOTPView(APIView):
    """POST /api/auth/resend-otp/ - kwa OTP iliyoisha muda au kupotea."""
    permission_classes = [AllowAny]

    def post(self, request):
        phone_number = request.data.get("phone_number")
        user = models.User.objects.filter(
            phone_number=phone_number, role=models.User.Role.OWNER, phone_verified=False
        ).first()
        if not user:
            return Response({"error": "Hakuna usajili unaosubiri uthibitisho kwa namba hii."},
                             status=status.HTTP_404_NOT_FOUND)

        otp = models.OTPVerification.objects.create(
            user=user, phone_number=phone_number, code=_generate_otp_code(),
            expires_at=timezone.now() + timedelta(minutes=10),
        )
        send_sms(phone_number, f"SafeTrade: OTP yako mpya ni {otp.code}.")
        return Response({"message": "OTP mpya imetumwa."})


class MeView(APIView):
    """GET /api/auth/me/ - taarifa za mtumiaji aliyeingia (role-based routing app-side)."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(serializers.UserSerializer(request.user).data)


# =============================================================================
# BUSINESS / STORE / STAFF
# =============================================================================

class BusinessViewSet(viewsets.ModelViewSet):
    serializer_class = serializers.BusinessSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == models.User.Role.SUPER_ADMIN:
            return models.Business.objects.all()
        return models.Business.objects.filter(owner=user)

    def perform_create(self, serializer):
        # Business ya ziada (Multi-store) kwa Owner aliyeshathibitishwa
        # kupitia NIDA+OTP tayari - haihitaji kusubiri uthibitisho mwingine.
        status_value = (
            models.Business.Status.ACTIVE
            if self.request.user.phone_verified
            else models.Business.Status.PENDING
        )
        serializer.save(owner=self.request.user, status=status_value)


class StoreViewSet(viewsets.ModelViewSet):
    serializer_class = serializers.StoreSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == models.User.Role.SUPER_ADMIN:
            return models.Store.objects.all()
        if user.role == models.User.Role.OWNER:
            return models.Store.objects.filter(business__owner=user)
        return models.Store.objects.filter(id=user.store_id)


class StaffViewSet(viewsets.ModelViewSet):
    """Owner PEKEE anaruhusiwa hapa - kutengeneza/kusimamia Storekeeper & Cashier."""
    permission_classes = [IsAuthenticated, perms.IsOwner]

    def get_serializer_class(self):
        if self.action == "create":
            return serializers.CreateStaffSerializer
        return serializers.UserSerializer

    def get_queryset(self):
        return models.User.objects.filter(created_by=self.request.user)

    @action(detail=True, methods=["patch"], url_path="credentials")
    def update_credentials(self, request, pk=None):
        """
        Sheria ya blueprint: wafanyakazi HAWAWEZI kubadilisha credentials zao
        wenyewe - Owner PEKEE ndiye mwenye mamlaka hii (endpoint hii tayari
        imefungwa kwa IsOwner juu, na get_queryset inahakikisha ni
        mfanyakazi wake tu).
        """
        staff = self.get_object()
        new_username = request.data.get("username")
        new_password = request.data.get("password")
        if new_username:
            staff.username = new_username
        if new_password:
            staff.set_password(new_password)
        staff.security_alert_pending = False
        staff.save()
        log_action(request.user, "credentials_reset", staff)
        return Response({"status": "updated"})

    @action(detail=False, methods=["post"], url_path="security-alert",
            permission_classes=[IsAuthenticated])
    def raise_security_alert(self, request):
        """Storekeeper/Cashier anabonyeza kitufe cha dharura."""
        user = request.user
        user.security_alert_pending = True
        user.save(update_fields=["security_alert_pending"])
        log_action(user, "security_alert_raised", user)
        return Response({"status": "owner_notified"})


# =============================================================================
# PRODUCTS / STOCK
# =============================================================================

class ProductViewSet(viewsets.ModelViewSet):
    serializer_class = serializers.ProductSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == models.User.Role.OWNER:
            return models.Product.objects.filter(business__owner=user)
        if user.store_id:
            return models.Product.objects.filter(business__stores__id=user.store_id)
        return models.Product.objects.none()


class ShelfStockViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = serializers.ShelfStockSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == models.User.Role.OWNER:
            return models.ShelfStock.objects.filter(store__business__owner=user)
        return models.ShelfStock.objects.filter(store_id=user.store_id)


class StockTransferViewSet(viewsets.ModelViewSet):
    """
    Storekeeper -> anaanzisha (create).
    Cashier -> anathibitisha (accept action).
    """
    serializer_class = serializers.StockTransferSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return models.StockTransfer.objects.filter(
            product__business__stores__id=self.request.user.store_id
        ) | models.StockTransfer.objects.filter(
            product__business__owner=self.request.user
        )

    def perform_create(self, serializer):
        if self.request.user.role != models.User.Role.STOREKEEPER:
            raise PermissionError("Storekeeper pekee ndiye anaanzisha uhamisho.")

        local_uuid = serializer.validated_data.get("local_uuid")
        existing = models.StockTransfer.objects.filter(local_uuid=local_uuid).first()
        if existing:
            # Idempotent kwa ajili ya offline sync retry - kama Storekeeper
            # ametuma ombi hili tayari (mfano wakati wa sync ya offline
            # queue), HATUONGEZI stock movement mara ya pili.
            serializer.instance = existing
            return

        transfer = serializer.save(initiated_by=self.request.user)

        # Warehouse stock inapungua mara moja kwa hali ya "pending_transfer"
        # ili isionekane inapatikana mara mbili wakati inasubiri ACCEPT.
        with transaction.atomic():
            warehouse_stock, _ = models.ShelfStock.objects.select_for_update().get_or_create(
                store_id=self.request.user.store_id,
                product=transfer.product,
                location_type=models.ShelfStock.LocationType.WAREHOUSE,
                shelf_code="",
                defaults={"quantity": 0},
            )
            warehouse_stock.quantity -= transfer.quantity_sent
            warehouse_stock.save()
        log_action(self.request.user, "stock_transfer_initiated", transfer,
                   {"quantity_sent": transfer.quantity_sent})

    @action(detail=True, methods=["post"], permission_classes=[IsAuthenticated, perms.IsCashier])
    @transaction.atomic
    def accept(self, request, pk=None):
        transfer = self.get_object()
        if transfer.status != models.StockTransfer.Status.PENDING:
            return Response({"error": "Uhamisho huu tayari umeshughulikiwa."},
                             status=status.HTTP_400_BAD_REQUEST)

        serializer = serializers.AcceptStockTransferSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        quantity_received = serializer.validated_data["quantity_received"]

        transfer.quantity_received = quantity_received
        transfer.status = models.StockTransfer.Status.ACCEPTED
        transfer.accepted_by = request.user
        transfer.accepted_at = timezone.now()
        transfer.save()

        counter_stock, _ = models.ShelfStock.objects.select_for_update().get_or_create(
            store_id=request.user.store_id,
            product=transfer.product,
            location_type=models.ShelfStock.LocationType.COUNTER,
            shelf_code="",
            defaults={"quantity": 0},
        )
        counter_stock.quantity += quantity_received
        counter_stock.save()

        log_action(request.user, "stock_transfer_accepted", transfer,
                   {"quantity_received": quantity_received})

        # Tofauti ya idadi -> DiscrepancyFlag (Anti-Theft System)
        if quantity_received != transfer.quantity_sent:
            models.DiscrepancyFlag.objects.create(
                store_id=request.user.store_id,
                product=transfer.product,
                expected_quantity=transfer.quantity_sent,
                actual_quantity=quantity_received,
            )

        return Response(serializers.StockTransferSerializer(transfer).data)


class DiscrepancyFlagViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = serializers.DiscrepancyFlagSerializer
    permission_classes = [IsAuthenticated, perms.IsOwner]

    def get_queryset(self):
        return models.DiscrepancyFlag.objects.filter(store__business__owner=self.request.user)


class StockIntakeViewSet(viewsets.mixins.CreateModelMixin,
                          viewsets.mixins.ListModelMixin,
                          viewsets.mixins.RetrieveModelMixin,
                          viewsets.GenericViewSet):
    """
    "Kila mzigo unapoingia Stoo" - Storekeeper anaandika gharama halisi
    (bei ya ununuzi kwa kipande/kifungu, usafiri, gharama nyingine).
    HAKUNA update/delete kwa makusudi - kama gharama imeandikwa vibaya,
    Storekeeper anaandika intake mpya ya kurekebisha (audit trail safi),
    sawa na sheria ya "hakuna kubadilisha risiti".
    """
    serializer_class = serializers.StockIntakeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == models.User.Role.OWNER:
            return models.StockIntake.objects.filter(store__business__owner=user)
        return models.StockIntake.objects.filter(store_id=user.store_id)

    def create(self, request, *args, **kwargs):
        if request.user.role != models.User.Role.STOREKEEPER:
            return Response(
                {"error": "Storekeeper pekee ndiye anaandika mzigo mpya."},
                status=status.HTTP_403_FORBIDDEN,
            )
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        product = data["product"]
        store = models.Store.objects.get(id=request.user.store_id)
        try:
            intake = record_stock_intake(
                store=store,
                product=product,
                quantity_received=data["quantity_received"],
                is_bundle_purchase=data.get("is_bundle_purchase", False),
                units_per_bundle=data.get("units_per_bundle", 1),
                bundle_cost_price=data.get("bundle_cost_price"),
                unit_cost_price=data.get("unit_cost_price"),
                transport_cost=data.get("transport_cost", 0),
                other_costs=data.get("other_costs", 0),
                recorded_by=request.user,
            )
        except ValueError as exc:
            raise DRFValidationError({"error": str(exc)})

        log_action(request.user, "stock_intake_recorded", intake, {
            "product": str(product.id), "total_cost": str(intake.total_cost),
        })
        return Response(
            serializers.StockIntakeSerializer(intake).data, status=status.HTTP_201_CREATED
        )


class ExpenseViewSet(viewsets.ModelViewSet):
    """
    Gharama za jumla za biashara (kodi, umeme, mishahara, usafiri wa
    kawaida) - siyo za mzigo maalum. Storekeeper/Owner wanaweza kuandika.
    """
    serializer_class = serializers.ExpenseSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == models.User.Role.OWNER:
            return models.Expense.objects.filter(store__business__owner=user)
        return models.Expense.objects.filter(store_id=user.store_id)

    def perform_create(self, serializer):
        expense = serializer.save(
            store_id=self.request.user.store_id, recorded_by=self.request.user
        )
        log_action(self.request.user, "expense_recorded", expense,
                   {"category": expense.category, "amount": str(expense.amount)})


class ProfitLossReportView(APIView):
    """
    GET /api/reports/profit-loss/?store=<id>&period=daily|weekly|monthly
    Ripoti kamili ya faida/hasara - mapato, COGS, gharama za uendeshaji
    (usafiri ukitengwa pekee), na faida/hasara halisi (net).
    """
    permission_classes = [IsAuthenticated, perms.IsOwner]

    def get(self, request):
        store_id = request.query_params.get("store")
        period = request.query_params.get("period", "daily")
        store = models.Store.objects.filter(
            id=store_id, business__owner=request.user
        ).first()
        if not store:
            return Response({"error": "Duka halikupatikana."}, status=404)
        try:
            report = get_profit_loss_report(store, period=period)
        except ValueError as exc:
            return Response({"error": str(exc)}, status=400)
        return Response(serializers.ProfitLossReportSerializer(report).data)


# =============================================================================
# SHIFTS
# =============================================================================

class ShiftViewSet(viewsets.ModelViewSet):
    serializer_class = serializers.ShiftSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return models.Shift.objects.filter(user=self.request.user)

    @action(detail=False, methods=["post"], url_path="clock-in")
    def clock_in(self, request):
        existing = models.Shift.objects.filter(
            user=request.user, status=models.Shift.Status.ACTIVE
        ).first()
        if existing:
            return Response({"error": "Tayari uko kwenye shift inayoendelea."},
                             status=status.HTTP_400_BAD_REQUEST)
        shift = models.Shift.objects.create(user=request.user, store_id=request.user.store_id)
        log_action(request.user, "clock_in", shift)
        return Response(serializers.ShiftSerializer(shift).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["post"], url_path="clock-out")
    def clock_out(self, request, pk=None):
        shift = self.get_object()
        if shift.status == models.Shift.Status.CLOSED:
            return Response({"error": "Shift hii tayari imefungwa."},
                             status=status.HTTP_400_BAD_REQUEST)

        receipts = models.Receipt.objects.filter(shift=shift)
        summary = {
            "total_receipts": receipts.count(),
            "cash_total": str(receipts.filter(
                payment_method=models.Receipt.PaymentMethod.CASH
            ).aggregate(t=Sum("total_amount"))["t"] or Decimal("0")),
            "lipa_namba_total": str(receipts.filter(
                payment_method=models.Receipt.PaymentMethod.LIPA_NAMBA
            ).aggregate(t=Sum("total_amount"))["t"] or Decimal("0")),
            "digital_receipts_sent": receipts.filter(sms_or_softcopy_sent=True).count(),
        }
        shift.status = models.Shift.Status.CLOSED
        shift.clock_out = timezone.now()
        shift.summary_json = summary
        shift.save()
        log_action(request.user, "clock_out", shift, summary)
        return Response(serializers.ShiftSerializer(shift).data)

    @action(detail=False, methods=["get"], url_path="active")
    def active_shift(self, request):
        """Inarudisha shift inayoendelea ya mtumiaji, au 404 kama hakuna."""
        shift = models.Shift.objects.filter(
            user=request.user, status=models.Shift.Status.ACTIVE
        ).first()
        if not shift:
            return Response({"error": "Hakuna shift inayoendelea."}, status=404)
        return Response(serializers.ShiftSerializer(shift).data)

    @action(detail=False, methods=["get"], url_path="current-history")
    def current_history(self, request):
        """Cashier anaona risiti ZOTE za shift yake ya sasa - READ ONLY."""
        shift = models.Shift.objects.filter(
            user=request.user, status=models.Shift.Status.ACTIVE
        ).first()
        if not shift:
            return Response({"error": "Hakuna shift inayoendelea."}, status=404)
        receipts = models.Receipt.objects.filter(shift=shift)
        return Response(serializers.ReceiptSerializer(receipts, many=True).data)


# =============================================================================
# RECEIPTS (create, offline sync) - HAKUNA update/delete kwa makusudi
# =============================================================================

class ReceiptViewSet(viewsets.mixins.CreateModelMixin,
                      viewsets.mixins.RetrieveModelMixin,
                      viewsets.mixins.ListModelMixin,
                      viewsets.GenericViewSet):
    """
    Kwa makusudi HAKUNA UpdateModelMixin wala DestroyModelMixin - kutekeleza
    sheria ya blueprint: "Cashier HANA UWEZO wa kufuta wala kubadilisha
    risiti yoyote aliyokwisha kuikata."
    """
    serializer_class = serializers.ReceiptSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == models.User.Role.OWNER:
            return models.Receipt.objects.filter(store__business__owner=user)
        return models.Receipt.objects.filter(cashier=user)

    @transaction.atomic
    def perform_create(self, serializer):
        user = self.request.user
        shift = models.Shift.objects.filter(
            user=user, status=models.Shift.Status.ACTIVE
        ).select_for_update().first()
        if not shift:
            raise ValueError("Lazima uwe umeingia shift (clock-in) kabla ya kukata risiti.")

        items_data = serializer.validated_data.pop("items")
        total = sum(item["quantity"] * item["unit_price"] for item in items_data)

        receipt = serializer.save(cashier=user, shift=shift, total_amount=total)

        for item_data in items_data:
            models.ReceiptItem.objects.create(receipt=receipt, **item_data)
            # Punguza stock ya Counter - "Masharti ya Mauzo" (Sehemu 3):
            # bidhaa inapungua PALE TU risiti inapotolewa.
            counter_stock = models.ShelfStock.objects.select_for_update().get(
                store=receipt.store, product=item_data["product"],
                location_type=models.ShelfStock.LocationType.COUNTER, shelf_code="",
            )
            counter_stock.quantity -= item_data["quantity"]
            counter_stock.save()

        # Faida/Hasara ya risiti hii - inanasa cost_price ya WAKATI HUO
        # (snapshot) na kukokotoa COGS/gross_profit papo hapo.
        apply_receipt_costing(receipt)

        try:
            calculate_and_record_pos_fee(receipt)
        except NoFeeTierConfiguredError as exc:
            raise DRFValidationError({"fee_configuration": str(exc)})
        log_action(user, "receipt_created", receipt, {"total": str(total)})


class OfflineReceiptSyncView(APIView):
    """
    POST /api/sync/receipts/
    Cashier anatuma batch ya risiti zilizokatwa OFFLINE. Idempotent kwa
    kutumia local_uuid - risiti iliyokwisha syncwa haitengenezwi tena.
    """
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        batch = request.data.get("receipts", [])
        results = []
        for entry in batch:
            local_uuid = entry.get("local_uuid")
            if models.Receipt.objects.filter(local_uuid=local_uuid).exists():
                results.append({"local_uuid": local_uuid, "status": "already_synced"})
                continue

            serializer = serializers.ReceiptSerializer(data=entry)
            serializer.is_valid(raise_exception=True)
            items_data = serializer.validated_data.pop("items")
            total = sum(item["quantity"] * item["unit_price"] for item in items_data)

            shift = models.Shift.objects.filter(
                user=request.user, status=models.Shift.Status.ACTIVE
            ).first()

            receipt = serializer.save(
                cashier=request.user, shift=shift, total_amount=total,
                created_offline=True, synced_at=timezone.now(),
            )
            for item_data in items_data:
                models.ReceiptItem.objects.create(receipt=receipt, **item_data)
                # Punguza stock ya Counter (ilikuwa AINA ya hitilafu
                # iliyokuwepo tangu awali - sync haikuwa ikigusa
                # ShelfStock kabisa). Ruhusu hasi kama kifaa cha offline
                # kiliuza zaidi ya cache yake ya ndani ilivyoonyesha
                # (mfano vifaa viwili tofauti viliuza bidhaa ile ile
                # wakati wote viko offline) - hii itaonekana kama
                # DiscrepancyFlag kwenye Owner dashboard badala ya
                # kuzuia sync kabisa.
                counter_stock, _ = models.ShelfStock.objects.select_for_update().get_or_create(
                    store=receipt.store, product=item_data["product"],
                    location_type=models.ShelfStock.LocationType.COUNTER, shelf_code="",
                    defaults={"quantity": 0},
                )
                new_qty = counter_stock.quantity - item_data["quantity"]
                if new_qty < 0:
                    models.DiscrepancyFlag.objects.create(
                        store=receipt.store, product=item_data["product"],
                        expected_quantity=counter_stock.quantity,
                        actual_quantity=-item_data["quantity"],
                    )
                counter_stock.quantity = new_qty
                counter_stock.save()

            apply_receipt_costing(receipt)

            try:
                calculate_and_record_pos_fee(receipt)
            except NoFeeTierConfiguredError as exc:
                raise DRFValidationError({"fee_configuration": str(exc)})
            # TODO (Awamu 2): queue Celery task ya kutuma SMS/WhatsApp "Tena Online"
            results.append({"local_uuid": local_uuid, "status": "synced",
                             "receipt_id": str(receipt.id)})
        return Response({"results": results})


# =============================================================================
# MARKETPLACE
# =============================================================================

class MarketplaceListingViewSet(viewsets.ModelViewSet):
    serializer_class = serializers.MarketplaceListingSerializer

    def get_permissions(self):
        if self.action in ("list", "retrieve"):
            return [IsAuthenticated()]
        return [IsAuthenticated(), perms.IsCashier()]

    def get_queryset(self):
        return models.MarketplaceListing.objects.filter(is_active=True)

    def perform_create(self, serializer):
        serializer.save(posted_by=self.request.user, store_id=self.request.user.store_id)


class DeliveryOptionViewSet(viewsets.ModelViewSet):
    serializer_class = serializers.DeliveryOptionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = models.DeliveryOption.objects.filter(is_active=True)
        store_id = self.request.query_params.get("store")
        if store_id:
            qs = qs.filter(store_id=store_id)
        return qs


class CartViewSet(viewsets.ModelViewSet):
    serializer_class = serializers.CartSerializer
    permission_classes = [IsAuthenticated, perms.IsCustomer]

    def get_queryset(self):
        return models.Cart.objects.filter(customer=self.request.user, checked_out=False)

    def perform_create(self, serializer):
        serializer.save(customer=self.request.user)

    @action(detail=True, methods=["post"], url_path="add-item")
    def add_item(self, request, pk=None):
        cart = self.get_object()
        listing_id = request.data.get("listing")
        quantity = int(request.data.get("quantity", 1))
        item, created = models.CartItem.objects.get_or_create(
            cart=cart, listing_id=listing_id, defaults={"quantity": quantity}
        )
        if not created:
            item.quantity += quantity
            item.save()
        return Response(serializers.CartSerializer(cart).data)

    @action(detail=True, methods=["post"], url_path="checkout")
    @transaction.atomic
    def checkout(self, request, pk=None):
        """
        Cart & Bulk Payments (Sehemu 3): risiti moja kwa kila bidhaa,
        malipo moja kwa jumla (bidhaa + delivery vinasomwa PAMOJA kama
        kiasi kimoja - "gharama usome kwa pamoja").

        Mtiririko wa malipo baada ya mteja kulipa jumla hii MOJA:
        - Malipo ya muuzaji (thamani ya bidhaa) yanakamilika MARA MOJA -
          angalia credit_seller_sale_proceeds().
        - Kwa delivery ya Bolt PEKEE: sehemu ya delivery HAITOLEWI kwa
          dereva mpaka mteja athibitishe amepokea mzigo (confirm_delivery
          hapa chini) - hii inazuia dereva kuchukua kazi nyingine kabla
          ya kupeleka mzigo huu.
        - Pickup (mteja/mtu wake anachukua dukani mwenyewe) -> hakuna
          delivery_fee wala DeliveryRequest kabisa.
        """
        cart = self.get_object()
        items = cart.items.select_related("listing__product", "listing__store").all()
        if not items:
            return Response({"error": "Cart iko tupu."}, status=400)

        store = items[0].listing.store
        subtotal = sum(i.quantity * i.listing.product.unit_price for i in items)

        delivery_option_id = request.data.get("delivery_option")
        delivery_option = (
            models.DeliveryOption.objects.filter(id=delivery_option_id).first()
            if delivery_option_id else None
        )

        delivery_fee = Decimal("0")
        if delivery_option:
            if delivery_option.kind == models.DeliveryOption.Kind.CUSTOM:
                delivery_fee = delivery_option.custom_flat_fee or Decimal("0")
            elif delivery_option.kind == models.DeliveryOption.Kind.BOLT:
                # Bolt haijaunganishwa bado (angalia core/services/bolt.py) -
                # mteja anaweza kupitisha kiasi cha makadirio kilichopatikana
                # kwenye app (quote ya awali) ili "kusomwa pamoja" na
                # subtotal, lakini gharama HALISI itahesabiwa moja kwa moja
                # na Bolt API mara itakapokuwa tayari.
                delivery_fee = Decimal(str(request.data.get("bolt_estimated_fee", "0") or "0"))
            # PICKUP na FREE -> delivery_fee inabaki 0

        order = models.Order.objects.create(
            customer=request.user, store=store, delivery_option=delivery_option,
            delivery_fee=delivery_fee, subtotal_amount=subtotal,
            total_amount=subtotal + delivery_fee,
            payment_method=request.data.get("payment_method", ""),
        )
        for i in items:
            models.OrderItem.objects.create(
                order=order, listing=i.listing, quantity=i.quantity,
                unit_price=i.listing.product.unit_price,
            )
        cart.checked_out = True
        cart.save()

        # 1) Muuzaji analipwa MARA MOJA - haisubiri delivery.
        credit_seller_sale_proceeds(order)

        # 2) Ada ya SafeTrade (POS-equivalent kwa Marketplace).
        try:
            calculate_and_record_marketplace_fee(order)
        except NoFeeTierConfiguredError as exc:
            raise DRFValidationError({"fee_configuration": str(exc)})

        # 3) DeliveryRequest - HAIUNDWI kwa Pickup (hakuna delivery kabisa).
        is_pickup = (
            delivery_option is None
            or delivery_option.kind == models.DeliveryOption.Kind.PICKUP
        )
        if not is_pickup:
            models.DeliveryRequest.objects.create(
                order=order,
                quoted_cost=delivery_fee if delivery_fee > 0 else None,
                # Bolt -> pesa ya delivery inabaki "imeshikiliwa" (haijawahi
                # kuguswa) mpaka confirm_delivery iitwe. Free/Custom -> siyo
                # suala la SafeTrade kuishikilia (fedha ya duka lenyewe).
            )

        log_action(request.user, "order_checked_out", order, {"total": str(order.total_amount)})
        return Response(serializers.OrderSerializer(order).data, status=201)

    @action(detail=True, methods=["post"], url_path="confirm-delivery",
            permission_classes=[IsAuthenticated])
    @transaction.atomic
    def confirm_delivery(self, request, pk=None):
        """
        Mteja (au Cashier akimwakilisha) anathibitisha amepokea mzigo wake.
        Kwa Bolt PEKEE: hapa ndipo pesa ya delivery INATOLEWA kwa dereva -
        KABLA ya hapa, haijawahi kuguswa kabisa (angalia checkout() hapo juu).
        """
        order = self.get_object()
        delivery_request = getattr(order, "delivery_request", None)
        if not delivery_request:
            return Response(
                {"error": "Oda hii ni Pickup au haina delivery ya kufuatilia."},
                status=400,
            )
        if delivery_request.status == models.DeliveryRequest.Status.DELIVERED:
            return Response({"message": "Tayari imethibitishwa kupokelewa."})

        delivery_request.status = models.DeliveryRequest.Status.DELIVERED
        order.status = models.Order.Status.DELIVERED

        if (order.delivery_option
                and order.delivery_option.kind == models.DeliveryOption.Kind.BOLT
                and not delivery_request.payment_released_to_courier):
            from .services.bolt import release_payment_to_courier
            release_payment_to_courier(delivery_request)
            delivery_request.payment_released_to_courier = True
            delivery_request.released_at = timezone.now()

        delivery_request.save()
        order.save(update_fields=["status"])
        log_action(request.user, "delivery_confirmed", order)
        return Response(serializers.OrderSerializer(order).data)


class OrderViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = serializers.OrderSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == models.User.Role.CUSTOMER:
            return models.Order.objects.filter(customer=user)
        if user.role == models.User.Role.OWNER:
            return models.Order.objects.filter(store__business__owner=user)
        return models.Order.objects.filter(store_id=user.store_id)


# =============================================================================
# PREDICTIVE ANALYTICS (read endpoints; hesabu halisi ni Celery task - tasks.py)
# =============================================================================

class PredictiveAlertViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = serializers.PredictiveAlertSerializer
    permission_classes = [IsAuthenticated, perms.IsOwner]

    def get_queryset(self):
        return models.PredictiveAlert.objects.filter(
            store__business__owner=self.request.user, acknowledged=False
        )

    @action(detail=False, methods=["post"], url_path="recompute")
    def recompute(self, request):
        """Owner anaomba Predictive Analytics ikokotolewe upya papo hapo
        badala ya kusubiri Celery Beat (kila masaa 6)."""
        from .services.predictive_analytics import run_predictive_analytics
        count = run_predictive_analytics()
        return Response({"message": f"Alerts {count} zimekokotolewa upya."})

    @action(detail=True, methods=["post"], url_path="acknowledge")
    def acknowledge(self, request, pk=None):
        alert = self.get_object()
        alert.acknowledged = True
        alert.save(update_fields=["acknowledged"])
        return Response({"status": "acknowledged"})


# =============================================================================
# DASHBOARD (Owner Absolute Transparency)
# =============================================================================

class OwnerDashboardView(APIView):
    permission_classes = [IsAuthenticated, perms.IsOwner]

    def get(self, request):
        stores = models.Store.objects.filter(business__owner=request.user)
        data = []
        for store in stores:
            warehouse_qty = models.ShelfStock.objects.filter(
                store=store, location_type=models.ShelfStock.LocationType.WAREHOUSE
            ).aggregate(t=Sum("quantity"))["t"] or 0
            counter_qty = models.ShelfStock.objects.filter(
                store=store, location_type=models.ShelfStock.LocationType.COUNTER
            ).aggregate(t=Sum("quantity"))["t"] or 0
            active_shifts = models.Shift.objects.filter(
                store=store, status=models.Shift.Status.ACTIVE
            ).count()
            today_sales = models.Receipt.objects.filter(
                store=store, created_at__date=timezone.now().date()
            ).aggregate(t=Sum("total_amount"))["t"] or Decimal("0")
            open_discrepancies = models.DiscrepancyFlag.objects.filter(
                store=store, resolved=False
            ).count()
            # Faida/Hasara ya LEO - alert ya moja kwa moja kwenye dashibodi
            # (kwa mujibu wa maombi: "impe mmiliki alert ya hasara na
            # kiasi cha hasara, na kama ni faida aone pia").
            today_report = get_profit_loss_report(store, period="daily")

            data.append({
                "store_id": str(store.id),
                "store_name": store.name,
                "warehouse_stock_total": warehouse_qty,
                "counter_stock_total": counter_qty,
                "active_shifts": active_shifts,
                "today_sales": str(today_sales),
                "open_discrepancy_flags": open_discrepancies,
                "today_net_profit": str(today_report["net_profit"]),
                "today_is_loss": today_report["is_loss"],
            })
        return Response({"stores": data})


class AuditLogListView(generics.ListAPIView):
    serializer_class = serializers.AuditLogSerializer
    permission_classes = [IsAuthenticated, perms.IsOwner]

    def get_queryset(self):
        return models.AuditLog.objects.filter(
            actor__store__business__owner=self.request.user
        ).order_by("-timestamp")[:500]
