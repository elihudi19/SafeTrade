import uuid

from django.contrib.auth.models import AbstractUser
from django.db import models


# =============================================================================
# 1. BUSINESS / STORE / USERS
# =============================================================================

class Business(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        ACTIVE = "active", "Active"
        SUSPENDED = "suspended", "Suspended"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.ForeignKey(
        "core.User", on_delete=models.CASCADE, related_name="owned_businesses"
    )
    name = models.CharField(max_length=255)
    # Leseni SIYO tena sharti la kuwasha duka (Owner sasa anathibitishwa
    # kupitia NIDA + OTP - angalia User.nida_number na OTPVerification
    # hapa chini). Field hii imebaki kama HIARI kwa maombi mengine ya
    # baadaye ya uzingatiaji wa kisheria, siyo lango la Business.status.
    license_document = models.FileField(upload_to="licenses/", null=True, blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class Store(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name="stores")
    name = models.CharField(max_length=255)
    location = models.CharField(max_length=255, blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.name} ({self.business.name})"


class User(AbstractUser):
    class Role(models.TextChoices):
        SUPER_ADMIN = "super_admin", "Super Admin"
        OWNER = "owner", "Business Owner"
        STOREKEEPER = "storekeeper", "Storekeeper"
        CASHIER = "cashier", "Cashier"
        CUSTOMER = "customer", "Customer"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    role = models.CharField(max_length=20, choices=Role.choices)
    store = models.ForeignKey(
        Store, on_delete=models.SET_NULL, null=True, blank=True, related_name="staff"
    )
    phone_number = models.CharField(max_length=32, blank=True)
    # Usajili wa Owner sasa unategemea NIDA (siyo leseni ya biashara) -
    # angalia core/services/nida.py na OwnerRegistrationView.
    nida_number = models.CharField(max_length=20, blank=True, null=True, unique=True)
    phone_verified = models.BooleanField(default=False)
    created_by = models.ForeignKey(
        "self", on_delete=models.SET_NULL, null=True, blank=True, related_name="created_users"
    )
    security_alert_pending = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.username} ({self.role})"


class OTPVerification(models.Model):
    """
    OTP ya kuthibitisha namba ya simu ya Owner baada ya NIDA API
    kuthibitisha kuwa namba ya simu imesajiliwa kwa NIDA namba husika.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="otp_codes")
    phone_number = models.CharField(max_length=32)
    code = models.CharField(max_length=6)
    is_used = models.BooleanField(default=False)
    attempts = models.PositiveSmallIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()

    def is_valid(self):
        return not self.is_used and timezone_now() < self.expires_at and self.attempts < 5


def timezone_now():
    from django.utils import timezone
    return timezone.now()


# =============================================================================
# 2. PRODUCTS / STOCK / STOCK TRANSFER
# =============================================================================

class Product(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name="products")
    sku = models.CharField(max_length=64)
    name = models.CharField(max_length=255)
    # unit_price = bei ya REJAREJA (retail) chaguo-msingi. wholesale_price
    # ni bei ya JUMLA chaguo-msingi (hiari - kama duka halitofautishi,
    # inabaki null na Cashier anaweza kuweka bei yoyote wakati wa mauzo).
    # Cashier ANARUHUSIWA kubadilisha bei hizi wakati wa kuuza kulingana
    # na makubaliano na Mmiliki - hizi ni "default" ya kuanzia tu, siyo
    # kikomo kigumu.
    unit_price = models.DecimalField(max_digits=12, decimal_places=2)
    wholesale_price = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    # cost_price = bei ya UNUNUZI (kwa kipande kimoja) - inasasishwa
    # KIOTOMATIKI kila StockIntake mpya inapoandikwa (angalia
    # core/services/costing.py). Hii ndiyo msingi wa kukokotoa faida/hasara
    # halisi ya kila risiti.
    cost_price = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    reorder_level = models.PositiveIntegerField(default=0)
    # Idadi ya siku kawaida inachukua kupata mzigo mpya ukishaagiza - hii
    # ndiyo msingi wa "Predictive Analytics" halisi (reorder point kwa
    # mujibu wa muda wa uagizaji), siyo tu kikomo tuli cha reorder_level.
    lead_time_days = models.PositiveIntegerField(default=3)

    class Meta:
        unique_together = ("business", "sku")

    def __str__(self):
        return self.name


class ShelfStock(models.Model):
    class LocationType(models.TextChoices):
        WAREHOUSE = "warehouse", "Warehouse"
        COUNTER = "counter", "Counter"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name="shelf_stocks")
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    location_type = models.CharField(max_length=20, choices=LocationType.choices)
    shelf_code = models.CharField(max_length=32, blank=True)
    quantity = models.IntegerField(default=0)

    class Meta:
        unique_together = ("store", "product", "location_type", "shelf_code")

    def __str__(self):
        return f"{self.product.name} @ {self.location_type} ({self.quantity})"


class StockTransfer(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending_transfer", "Pending Transfer"
        ACCEPTED = "accepted", "Accepted"
        REJECTED = "rejected", "Rejected"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    local_uuid = models.UUIDField(unique=True)
    product = models.ForeignKey(Product, on_delete=models.PROTECT)
    quantity_sent = models.PositiveIntegerField()
    quantity_received = models.PositiveIntegerField(null=True, blank=True)
    initiated_by = models.ForeignKey(User, on_delete=models.PROTECT, related_name="initiated_transfers")
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    accepted_by = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True, related_name="accepted_transfers"
    )
    accepted_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


class DiscrepancyFlag(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name="discrepancies")
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    expected_quantity = models.IntegerField()
    actual_quantity = models.IntegerField()
    flagged_at = models.DateTimeField(auto_now_add=True)
    resolved = models.BooleanField(default=False)


class StockIntake(models.Model):
    """
    Mzigo mpya unapoingia Stoo - Storekeeper anaandika GHARAMA HALISI ya
    mzigo huu: bei ya ununuzi (kwa kipande au kwa carton/kifungu), gharama
    ya usafiri, na gharama nyingine (kupakia, forodha, n.k.) - PEKEE PEKEE,
    kwa mujibu wa maombi yako ("gharama za usafiri zijitenge na gharama
    zingine").

    Hii ndiyo chanzo cha:
    - Product.cost_price (inasasishwa kiotomatiki - angalia
      core/services/costing.py::record_stock_intake)
    - ShelfStock ya Warehouse (inaongezeka kwa quantity_received)
    - suggested_min_selling_price (bei ya chini kabisa isiyo na hasara)
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name="stock_intakes")
    product = models.ForeignKey(Product, on_delete=models.PROTECT, related_name="stock_intakes")

    quantity_received = models.PositiveIntegerField(help_text="Idadi ya VIPANDE halisi (baada ya kufungua kifungu, kama kipo)")

    # Bei ya ununuzi - ima kwa kifungu (bundle) au moja kwa moja kwa kipande.
    is_bundle_purchase = models.BooleanField(default=False)
    units_per_bundle = models.PositiveIntegerField(default=1)
    bundle_cost_price = models.DecimalField(max_digits=14, decimal_places=2, null=True, blank=True)
    unit_cost_price = models.DecimalField(
        max_digits=12, decimal_places=2,
        help_text="Bei ya kipande kimoja - inakokotolewa kiotomatiki kutoka bundle_cost_price/units_per_bundle kama ni bundle",
    )

    # Gharama za mzigo huu MAALUM - USAFIRI umetengwa pekee kwa mujibu wa
    # maombi (ripoti zinaweza kuchambua transport dhidi ya gharama nyingine).
    transport_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    other_costs = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    # Zinakokotolewa kiotomatiki wakati wa kuandikwa (angalia costing.py) -
    # zimehifadhiwa kama fields (siyo property) ili ziweze kutumika kwenye
    # ripoti/queries za haraka bila kukokotoa upya kila wakati.
    total_cost = models.DecimalField(max_digits=14, decimal_places=2)
    suggested_min_selling_price = models.DecimalField(max_digits=12, decimal_places=2)

    recorded_by = models.ForeignKey(User, on_delete=models.PROTECT, related_name="stock_intakes")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Intake: {self.product.name} x{self.quantity_received} @ {self.created_at:%Y-%m-%d}"


class Expense(models.Model):
    """
    Gharama za JUMLA za biashara (siyo za mzigo maalum) - kodi ya duka,
    umeme, mishahara, n.k. Zinawekwa na Storekeeper/Owner kwa kipindi
    (siku/wiki/mwezi) ili ripoti ya faida/hasara iwe sahihi na ijumuishe
    gharama za uendeshaji, siyo tu bei ya bidhaa.
    """
    class Category(models.TextChoices):
        TRANSPORT = "transport", "Usafiri"
        RENT = "rent", "Kodi ya Duka"
        UTILITIES = "utilities", "Umeme/Maji"
        SALARIES = "salaries", "Mishahara"
        OTHER = "other", "Nyingine"

    class Period(models.TextChoices):
        DAILY = "daily", "Kila Siku"
        WEEKLY = "weekly", "Kila Wiki"
        MONTHLY = "monthly", "Kila Mwezi"
        ONE_TIME = "one_time", "Mara Moja"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name="expenses")
    category = models.CharField(max_length=20, choices=Category.choices)
    period = models.CharField(max_length=10, choices=Period.choices, default=Period.ONE_TIME)
    amount = models.DecimalField(max_digits=14, decimal_places=2)
    description = models.CharField(max_length=255, blank=True)
    # Tarehe husika ya gharama (siyo tarehe ya kuandikwa mfumoni) - kwa
    # gharama za "weekly"/"monthly", hii inawakilisha siku ya kuanzia
    # kipindi husika.
    expense_date = models.DateField()
    recorded_by = models.ForeignKey(User, on_delete=models.PROTECT, related_name="recorded_expenses")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-expense_date"]


# =============================================================================
# 3. SHIFTS
# =============================================================================

class Shift(models.Model):
    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        CLOSED = "closed", "Closed"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="shifts")
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name="shifts")
    clock_in = models.DateTimeField(auto_now_add=True)
    clock_out = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.ACTIVE)
    summary_json = models.JSONField(null=True, blank=True)


# =============================================================================
# 4. RECEIPTS (In-store POS sales)
# =============================================================================

class Receipt(models.Model):
    class PaymentMethod(models.TextChoices):
        CASH = "cash", "Cash"
        LIPA_NAMBA = "lipa_namba", "Lipa Namba"
        MPESA = "mpesa", "M-Pesa"
        TIGOPESA = "tigopesa", "Tigo Pesa"

    class ReceiptSource(models.TextChoices):
        THERMAL_PRINTER = "thermal_printer", "Thermal Printer"
        MANUAL_TEMPLATE = "manual_template", "Manual Template"
        SOFTCOPY_ONLY = "softcopy_only", "Softcopy Only"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    local_uuid = models.UUIDField(unique=True)
    store = models.ForeignKey(Store, on_delete=models.PROTECT, related_name="receipts")
    cashier = models.ForeignKey(User, on_delete=models.PROTECT, related_name="receipts")
    shift = models.ForeignKey(Shift, on_delete=models.PROTECT, related_name="receipts")
    customer_name = models.CharField(max_length=255, blank=True)
    customer_phone = models.CharField(max_length=32, blank=True)
    payment_method = models.CharField(max_length=20, choices=PaymentMethod.choices)
    total_amount = models.DecimalField(max_digits=14, decimal_places=2)
    receipt_source = models.CharField(max_length=20, choices=ReceiptSource.choices)
    sms_or_softcopy_sent = models.BooleanField(default=False)
    created_offline = models.BooleanField(default=False)
    synced_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    # Faida/Hasara ya risiti hii - inakokotolewa MOJA KWA MOJA wakati wa
    # kuundwa (angalia core/services/profit_loss.py::apply_receipt_costing)
    # kwa kutumia cost_price ya bidhaa wakati huo (siyo cost_price ya sasa,
    # kwa hiyo bado ni sahihi hata bei ya ununuzi ikibadilika baadaye).
    total_cost_of_goods = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    gross_profit = models.DecimalField(max_digits=14, decimal_places=2, default=0)


class ReceiptItem(models.Model):
    class SaleType(models.TextChoices):
        RETAIL = "retail", "Rejareja"
        WHOLESALE = "wholesale", "Jumla"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    receipt = models.ForeignKey(Receipt, on_delete=models.CASCADE, related_name="items")
    product = models.ForeignKey(Product, on_delete=models.PROTECT)
    quantity = models.PositiveIntegerField()
    # unit_price ni bei HALISI Cashier aliyouza kwayo - anaweza kuiweka
    # kulingana na makubaliano na Mmiliki (jumla/rejareja), SIYO lazima
    # ilingane na Product.unit_price/wholesale_price - hizo ni chaguo-msingi
    # tu za kumsaidia, si kikomo kigumu.
    unit_price = models.DecimalField(max_digits=12, decimal_places=2)
    sale_type = models.CharField(max_length=10, choices=SaleType.choices, default=SaleType.RETAIL)
    # Bei ya ununuzi (Product.cost_price) ILIVYOKUWA wakati risiti hii
    # ilipoundwa - "snapshot" hii ndiyo inayohakikisha faida/hasara
    # inabaki sahihi hata Product.cost_price ikibadilika baadaye.
    cost_price_snapshot = models.DecimalField(max_digits=12, decimal_places=2, default=0)


class AuditLog(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    actor = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    action = models.CharField(max_length=100)
    target_model = models.CharField(max_length=100)
    target_id = models.UUIDField()
    metadata_json = models.JSONField(null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)


# =============================================================================
# 5. MARKETPLACE (E-commerce)
# =============================================================================

class MarketplaceListing(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name="listings")
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name="listings")
    posted_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name="posted_listings")
    photo = models.ImageField(upload_to="listing_photos/")
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Listing: {self.product.name}"


class DeliveryOption(models.Model):
    class Kind(models.TextChoices):
        PICKUP = "pickup", "Pickup Mwenyewe Dukani (Bila Delivery)"
        FREE = "free", "Free Delivery"
        BOLT = "bolt", "Paid - Bolt API"
        CUSTOM = "custom", "Paid - Custom (mfano Bodaboda wa duka)"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name="delivery_options")
    kind = models.CharField(max_length=10, choices=Kind.choices)
    custom_flat_fee = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    free_delivery_min_order = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    is_active = models.BooleanField(default=True)


class Cart(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name="carts")
    created_at = models.DateTimeField(auto_now_add=True)
    checked_out = models.BooleanField(default=False)


class CartItem(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    cart = models.ForeignKey(Cart, on_delete=models.CASCADE, related_name="items")
    listing = models.ForeignKey(MarketplaceListing, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=1)


class Order(models.Model):
    class Status(models.TextChoices):
        PENDING_PAYMENT = "pending_payment", "Pending Payment"
        PAID = "paid", "Paid"
        DISPATCHED = "dispatched", "Dispatched"
        DELIVERED = "delivered", "Delivered"
        CANCELLED = "cancelled", "Cancelled"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    customer = models.ForeignKey(User, on_delete=models.PROTECT, related_name="orders")
    store = models.ForeignKey(Store, on_delete=models.PROTECT, related_name="orders")
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING_PAYMENT)
    delivery_option = models.ForeignKey(DeliveryOption, on_delete=models.SET_NULL, null=True)
    delivery_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    subtotal_amount = models.DecimalField(max_digits=14, decimal_places=2)
    total_amount = models.DecimalField(max_digits=14, decimal_places=2)
    payment_method = models.CharField(max_length=20, blank=True)
    # Malipo ya muuzaji (subtotal - ada) yanakamilika MARA MOJA baada ya
    # malipo ya mteja kuthibitika - HAYASUBIRI delivery kukamilika. Hii
    # field inazuia kukatwa/kukopeshwa mara mbili kwa bahati mbaya.
    seller_amount_credited = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)


class OrderItem(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name="items")
    listing = models.ForeignKey(MarketplaceListing, on_delete=models.PROTECT)
    quantity = models.PositiveIntegerField()
    unit_price = models.DecimalField(max_digits=12, decimal_places=2)
    receipt = models.ForeignKey(Receipt, on_delete=models.SET_NULL, null=True, blank=True)


class DeliveryRequest(models.Model):
    class Status(models.TextChoices):
        REQUESTED = "requested", "Requested"
        DRIVER_ASSIGNED = "driver_assigned", "Driver Assigned"
        PICKED_UP = "picked_up", "Picked Up"
        DELIVERED = "delivered", "Delivered"
        FAILED = "failed", "Failed"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.OneToOneField(Order, on_delete=models.CASCADE, related_name="delivery_request")
    bolt_tracking_id = models.CharField(max_length=128, blank=True)
    distance_km = models.FloatField(null=True, blank=True)
    quoted_cost = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.REQUESTED)
    # SHERIA MUHIMU (Bolt pekee): pesa ya delivery HAITOLEWI kwa dereva
    # mpaka mteja athibitishe amepokea mzigo wake - hii inazuia dereva
    # kuchukua kazi nyingine badala ya kupeleka mzigo huu kwanza. Kwa
    # Free/Custom, pesa (ikiwepo) siyo suala la SafeTrade kuishikilia
    # (ni fedha ya duka lenyewe/dereva wake), hivyo fields hizi zinabaki
    # False/null kwao kwa kawaida.
    payment_released_to_courier = models.BooleanField(default=False)
    released_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


# =============================================================================
# 6. WALLET / MONETIZATION
# =============================================================================

class Wallet(models.Model):
    class OwnerType(models.TextChoices):
        CASHIER = "cashier", "Cashier Wallet"
        BUSINESS = "business", "Business Wallet"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner_type = models.CharField(max_length=10, choices=OwnerType.choices)
    user = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True, related_name="wallet")
    business = models.ForeignKey(Business, on_delete=models.CASCADE, null=True, blank=True, related_name="wallet")
    balance = models.DecimalField(max_digits=16, decimal_places=2, default=0)

    class Meta:
        constraints = [
            models.CheckConstraint(
                check=(
                    models.Q(owner_type="cashier", user__isnull=False, business__isnull=True)
                    | models.Q(owner_type="business", business__isnull=False, user__isnull=True)
                ),
                name="wallet_owner_matches_type",
            )
        ]


class WalletTransaction(models.Model):
    class Kind(models.TextChoices):
        INTERNAL_TRANSFER = "internal_transfer", "Cashier -> Business Ledger Transfer"
        POS_FEE = "pos_fee", "POS Transaction Fee"
        MARKETPLACE_FEE_CUSTOMER = "marketplace_fee_customer", "Marketplace Fee (Customer)"
        MARKETPLACE_FEE_SELLER = "marketplace_fee_seller", "Marketplace Fee (Seller)"
        SALE_PROCEEDS = "sale_proceeds", "Malipo ya Mauzo kwa Muuzaji (Marketplace)"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    kind = models.CharField(max_length=30, choices=Kind.choices)
    wallet = models.ForeignKey(Wallet, on_delete=models.CASCADE, related_name="transactions")
    amount = models.DecimalField(max_digits=14, decimal_places=2)
    related_receipt = models.ForeignKey(Receipt, on_delete=models.SET_NULL, null=True, blank=True)
    related_order = models.ForeignKey(Order, on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


class FeeTier(models.Model):
    """
    Madaraja ya ada ya POS (kwa Muuzaji) - MCHANGANUO WA MAKATO YA SAFETRADE.

    fee_amount ni KIASI HALISI CHA TZS (flat fee) - hii ni ada KAMILI
    (inayotumika kwa mauzo ya kidijitali/SMS/Lipa Namba). Ada ya nusu
    (50% discount, inayotumika kwa cash bila SMS/softcopy) inakokotolewa
    moja kwa moja kama fee_amount/2 na core/services/fees.py -
    HAIHIFADHIWI hapa kama tier tofauti.
    """
    min_amount = models.DecimalField(max_digits=14, decimal_places=2)
    max_amount = models.DecimalField(max_digits=14, decimal_places=2, null=True, blank=True)
    fee_amount = models.DecimalField(max_digits=10, decimal_places=2)

    class Meta:
        ordering = ["min_amount"]


class MarketplaceFeeTier(models.Model):
    """
    Ada ya Mteja kwenye Marketplace (Oda Ndogo/Kubwa) - MCHANGANUO WA
    MAKATO YA SAFETRADE. customer_fee_amount ni KIASI HALISI CHA TZS
    (flat), SIYO asilimia. Ada ya Muuzaji kwenye Marketplace inatumia
    FeeTier (kamili/nusu) - angalia
    core/services/fees.py::calculate_and_record_marketplace_fee.
    """
    min_amount = models.DecimalField(max_digits=14, decimal_places=2)
    max_amount = models.DecimalField(max_digits=14, decimal_places=2, null=True, blank=True)
    customer_fee_amount = models.DecimalField(max_digits=10, decimal_places=2)

    class Meta:
        ordering = ["min_amount"]


# =============================================================================
# 7. PREDICTIVE ANALYTICS (v1 - rules-based, sio ML kamili bado)
# =============================================================================

class PredictiveAlert(models.Model):
    class AlertType(models.TextChoices):
        FAST_MOVING = "fast_moving", "Fast Moving / Reorder Level"
        SLOW_MOVING = "slow_moving", "Slow Moving"
        # Alerts za kibiashara kwa ujumla (siyo bidhaa moja) - utabiri wa
        # mwenendo wa faida/hasara ya duka. `product` inabaki null kwa hizi.
        LOSS_WARNING = "loss_warning", "Onyo la Hasara"
        PROFIT_TREND = "profit_trend", "Mwenendo wa Faida"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name="predictive_alerts")
    product = models.ForeignKey(Product, on_delete=models.CASCADE, null=True, blank=True)
    alert_type = models.CharField(max_length=20, choices=AlertType.choices)
    detail_json = models.JSONField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    acknowledged = models.BooleanField(default=False)
