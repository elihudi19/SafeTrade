from rest_framework import serializers

from . import models


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.User
        fields = ["id", "username", "role", "store", "phone_number", "is_active",
                  "security_alert_pending"]
        read_only_fields = ["id"]


class CreateStaffSerializer(serializers.ModelSerializer):
    """Owner pekee ndiye anatumia hii kutengeneza Storekeeper/Cashier."""
    password = serializers.CharField(write_only=True)

    class Meta:
        model = models.User
        fields = ["id", "username", "password", "role", "store", "phone_number"]

    def validate_role(self, value):
        if value not in (models.User.Role.STOREKEEPER, models.User.Role.CASHIER):
            raise serializers.ValidationError(
                "Owner anaweza kutengeneza Storekeeper au Cashier pekee."
            )
        return value

    def create(self, validated_data):
        password = validated_data.pop("password")
        user = models.User(**validated_data, created_by=self.context["request"].user)
        user.set_password(password)
        user.save()
        return user


class OwnerRegistrationSerializer(serializers.Serializer):
    """
    Usajili wa Business Owner - sasa kwa NIDA + OTP badala ya Leseni.
    """
    username = serializers.CharField(max_length=150)
    password = serializers.CharField(write_only=True, min_length=6)
    nida_number = serializers.CharField(max_length=20)
    phone_number = serializers.CharField(max_length=32)
    business_name = serializers.CharField(max_length=255)

    def validate_username(self, value):
        if models.User.objects.filter(username=value).exists():
            raise serializers.ValidationError("Username hii tayari inatumika.")
        return value

    def validate_nida_number(self, value):
        if models.User.objects.filter(nida_number=value).exists():
            raise serializers.ValidationError("NIDA namba hii tayari imesajiliwa.")
        return value


class VerifyOTPSerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=32)
    code = serializers.CharField(max_length=6)


class BusinessSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.Business
        fields = ["id", "name", "license_document", "status", "created_at"]
        read_only_fields = ["id", "status", "created_at"]
        extra_kwargs = {"license_document": {"required": False}}


class StoreSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.Store
        fields = ["id", "business", "name", "location", "latitude", "longitude", "is_active"]
        read_only_fields = ["id"]


class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.Product
        fields = ["id", "business", "sku", "name", "unit_price", "wholesale_price",
                  "cost_price", "reorder_level", "lead_time_days"]
        read_only_fields = ["id", "cost_price"]  # cost_price inasasishwa PEKEE na StockIntake


class ShelfStockSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source="product.name", read_only=True)

    class Meta:
        model = models.ShelfStock
        fields = ["id", "store", "product", "product_name", "location_type",
                  "shelf_code", "quantity"]
        read_only_fields = ["id"]


class StockTransferSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.StockTransfer
        fields = ["id", "local_uuid", "product", "quantity_sent", "quantity_received",
                  "initiated_by", "status", "accepted_by", "accepted_at", "created_at"]
        read_only_fields = ["id", "initiated_by", "status", "accepted_by",
                             "accepted_at", "created_at"]


class AcceptStockTransferSerializer(serializers.Serializer):
    quantity_received = serializers.IntegerField(min_value=0)


class ShiftSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.Shift
        fields = ["id", "user", "store", "clock_in", "clock_out", "status", "summary_json"]
        read_only_fields = ["id", "user", "clock_in", "clock_out", "status", "summary_json"]


class ReceiptItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.ReceiptItem
        fields = ["id", "product", "quantity", "unit_price", "sale_type", "cost_price_snapshot"]
        read_only_fields = ["id", "cost_price_snapshot"]  # snapshot inanaswa na backend, siyo client


class ReceiptSerializer(serializers.ModelSerializer):
    items = ReceiptItemSerializer(many=True)

    class Meta:
        model = models.Receipt
        fields = ["id", "local_uuid", "store", "cashier", "shift", "customer_name",
                  "customer_phone", "payment_method", "total_amount", "receipt_source",
                  "sms_or_softcopy_sent", "created_offline", "synced_at", "created_at",
                  "total_cost_of_goods", "gross_profit", "items"]
        read_only_fields = ["id", "cashier", "shift", "total_amount", "synced_at",
                             "created_at", "total_cost_of_goods", "gross_profit"]


class MarketplaceListingSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.MarketplaceListing
        fields = ["id", "product", "store", "posted_by", "photo", "description",
                  "is_active", "created_at"]
        read_only_fields = ["id", "posted_by", "created_at"]


class DeliveryOptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.DeliveryOption
        fields = ["id", "store", "kind", "custom_flat_fee", "free_delivery_min_order", "is_active"]
        read_only_fields = ["id"]


class CartItemSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source="listing.product.name", read_only=True)
    unit_price = serializers.DecimalField(
        source="listing.product.unit_price", max_digits=12, decimal_places=2, read_only=True
    )
    store = serializers.PrimaryKeyRelatedField(source="listing.store", read_only=True)

    class Meta:
        model = models.CartItem
        fields = ["id", "listing", "quantity", "product_name", "unit_price", "store"]
        read_only_fields = ["id", "product_name", "unit_price", "store"]


class CartSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True, read_only=True)

    class Meta:
        model = models.Cart
        fields = ["id", "customer", "created_at", "checked_out", "items"]
        read_only_fields = ["id", "customer", "created_at", "checked_out"]


class OrderItemSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source="listing.product.name", read_only=True)

    class Meta:
        model = models.OrderItem
        fields = ["id", "listing", "quantity", "unit_price", "receipt", "product_name"]
        read_only_fields = ["id", "unit_price", "receipt", "product_name"]


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    delivery_option_kind = serializers.CharField(source="delivery_option.kind", read_only=True, default=None)
    delivery_status = serializers.SerializerMethodField()

    class Meta:
        model = models.Order
        fields = ["id", "customer", "store", "status", "delivery_option", "delivery_option_kind",
                  "delivery_fee", "delivery_status", "subtotal_amount", "total_amount",
                  "payment_method", "created_at", "items"]
        read_only_fields = ["id", "customer", "status", "delivery_fee", "subtotal_amount",
                             "total_amount", "created_at"]

    def get_delivery_status(self, obj):
        delivery_request = getattr(obj, "delivery_request", None)
        return delivery_request.status if delivery_request else None


class DiscrepancyFlagSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.DiscrepancyFlag
        fields = ["id", "store", "product", "expected_quantity", "actual_quantity",
                  "flagged_at", "resolved"]
        read_only_fields = ["id", "flagged_at"]


class PredictiveAlertSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.PredictiveAlert
        fields = ["id", "store", "product", "alert_type", "detail_json",
                  "created_at", "acknowledged"]
        read_only_fields = ["id", "created_at"]


class WalletSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.Wallet
        fields = ["id", "owner_type", "user", "business", "balance"]
        read_only_fields = fields


class AuditLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.AuditLog
        fields = ["id", "actor", "action", "target_model", "target_id",
                  "metadata_json", "timestamp"]
        read_only_fields = fields


class StockIntakeSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source="product.name", read_only=True)

    class Meta:
        model = models.StockIntake
        fields = ["id", "store", "product", "product_name", "quantity_received",
                  "is_bundle_purchase", "units_per_bundle", "bundle_cost_price",
                  "unit_cost_price", "transport_cost", "other_costs", "total_cost",
                  "suggested_min_selling_price", "recorded_by", "created_at"]
        # MUHIMU: unit_cost_price NI INPUT (hiari - inatolewa na client
        # PEKEE kama siyo bundle purchase; kama ni bundle, view
        # inaikokotoa kutoka bundle_cost_price/units_per_bundle badala
        # yake). total_cost/suggested_min_selling_price ndizo OUTPUT
        # zilizokokotolewa - hizo pekee ni read-only za kweli.
        read_only_fields = ["id", "total_cost", "suggested_min_selling_price",
                             "recorded_by", "created_at"]
        extra_kwargs = {
            "bundle_cost_price": {"required": False},
            "unit_cost_price": {"required": False},
            # store inaamuliwa na backend kutoka request.user.store_id
            # (siyo client) - angalia StockIntakeViewSet.create.
            "store": {"required": False},
        }


class ExpenseSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.Expense
        fields = ["id", "store", "category", "period", "amount", "description",
                  "expense_date", "recorded_by", "created_at"]
        read_only_fields = ["id", "recorded_by", "created_at"]
        extra_kwargs = {"store": {"required": False}}


class ProfitLossReportSerializer(serializers.Serializer):
    period = serializers.CharField()
    start_date = serializers.CharField()
    end_date = serializers.CharField()
    revenue = serializers.DecimalField(max_digits=14, decimal_places=2)
    cost_of_goods_sold = serializers.DecimalField(max_digits=14, decimal_places=2)
    gross_profit = serializers.DecimalField(max_digits=14, decimal_places=2)
    transport_expenses = serializers.DecimalField(max_digits=14, decimal_places=2)
    other_operating_expenses = serializers.DecimalField(max_digits=14, decimal_places=2)
    total_operating_expenses = serializers.DecimalField(max_digits=14, decimal_places=2)
    net_profit = serializers.DecimalField(max_digits=14, decimal_places=2)
    is_loss = serializers.BooleanField()
    receipt_count = serializers.IntegerField()
