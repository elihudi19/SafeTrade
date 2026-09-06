"""
Mantiki ya Ada (Monetization Logic) - MCHANGANUO WA MAKATO YA SAFETRADE
(jedwali rasmi ulilotoa).

MUHIMU: Ada za POS (kwa Muuzaji) ni KIASI MAALUM CHA TZS (flat fee) kwa
kila daraja la thamani ya muamala - SIYO asilimia. Ada ya Mteja kwenye
Marketplace nazo ni fixed TZS (siyo asilimia).

Hakuna free tier: kila muamala LAZIMA ulingane na tier moja, la sivyo
NoFeeTierConfiguredError inatolewa na muamala mzima unarudishwa nyuma
(rollback) - angalia views.py kwa jinsi hii inavyoshughulikiwa kwenye API.
"""
from decimal import Decimal

from django.core.exceptions import ImproperlyConfigured
from django.db.models import Q

from core.models import FeeTier, MarketplaceFeeTier, Wallet, WalletTransaction, Receipt


class NoFeeTierConfiguredError(ImproperlyConfigured):
    """
    Inatolewa pale ambapo hakuna tier inayolingana na kiwango cha
    muamala. Run: python manage.py seed_fee_tiers
    """
    pass


def _find_tier(amount: Decimal) -> FeeTier:
    tier = FeeTier.objects.filter(min_amount__lte=amount).filter(
        Q(max_amount__isnull=True) | Q(max_amount__gte=amount)
    ).order_by("-min_amount").first()
    if not tier:
        raise NoFeeTierConfiguredError(
            f"Hakuna FeeTier inayolingana na kiasi cha TZS {amount}. "
            "Run 'python manage.py seed_fee_tiers' au ongeza FeeTier "
            "kupitia Django Admin kabla ya kuendelea."
        )
    return tier


def get_pos_full_fee(amount: Decimal) -> Decimal:
    """Ada Kamili ya POS (Muuzaji) - mauzo ya Digital/SMS/Lipa Namba."""
    return _find_tier(amount).fee_amount


def get_pos_half_fee(amount: Decimal) -> Decimal:
    """Nusu Ada (50% Discount) - inatumika kwa Cash bila SMS/Softcopy."""
    return (get_pos_full_fee(amount) / Decimal("2")).quantize(Decimal("0.01"))


def get_marketplace_customer_fee(amount: Decimal) -> Decimal:
    """Ada ya Mteja kwenye Marketplace (fixed TZS, siyo asilimia)."""
    tier = MarketplaceFeeTier.objects.filter(min_amount__lte=amount).filter(
        Q(max_amount__isnull=True) | Q(max_amount__gte=amount)
    ).order_by("-min_amount").first()
    if not tier:
        raise NoFeeTierConfiguredError(
            f"Hakuna MarketplaceFeeTier inayolingana na kiasi cha TZS {amount}. "
            "Run 'python manage.py seed_fee_tiers' au ongeza kupitia Django Admin."
        )
    return tier.customer_fee_amount


def credit_seller_sale_proceeds(order) -> Decimal:
    """
    'Malipo ya kwa muuzaji yakamilike kwanza' - mara tu mteja amelipa
    (order imeundwa), thamani ya bidhaa (subtotal_amount) inaongezwa
    kwenye Business Wallet MARA MOJA - HAISUBIRI delivery kukamilika.
    Hii ni tofauti kabisa na delivery_fee ya Bolt (angalia
    calculate_and_record_marketplace_fee na views.py::confirm_delivery).
    """
    if order.seller_amount_credited:
        return Decimal("0.00")  # kinga dhidi ya kukatwa/kuongezwa mara mbili

    business_wallet, _ = Wallet.objects.get_or_create(
        owner_type=Wallet.OwnerType.BUSINESS,
        business=order.store.business,
    )
    WalletTransaction.objects.create(
        kind=WalletTransaction.Kind.SALE_PROCEEDS,
        wallet=business_wallet,
        amount=order.subtotal_amount,
        related_order=order,
    )
    business_wallet.balance += order.subtotal_amount
    business_wallet.save(update_fields=["balance"])

    order.seller_amount_credited = True
    order.save(update_fields=["seller_amount_credited"])
    return order.subtotal_amount


def calculate_and_record_pos_fee(receipt: Receipt) -> Decimal:
    """
    Cash BILA SMS/Softcopy Receipt -> Nusu Ada, hakuna makato kwa mteja.
    Lipa Namba/Digital/SMS/WhatsApp Receipt -> Ada Kamili, hakuna makato kwa mteja.
    """
    is_cash_without_digital_receipt = (
        receipt.payment_method == Receipt.PaymentMethod.CASH
        and not receipt.sms_or_softcopy_sent
    )
    fee_amount = (
        get_pos_half_fee(receipt.total_amount)
        if is_cash_without_digital_receipt
        else get_pos_full_fee(receipt.total_amount)
    )

    business_wallet, _ = Wallet.objects.get_or_create(
        owner_type=Wallet.OwnerType.BUSINESS,
        business=receipt.store.business,
    )
    WalletTransaction.objects.create(
        kind=WalletTransaction.Kind.POS_FEE,
        wallet=business_wallet,
        amount=-fee_amount,
        related_receipt=receipt,
    )
    business_wallet.balance -= fee_amount
    business_wallet.save(update_fields=["balance"])
    return fee_amount


def calculate_and_record_marketplace_fee(order) -> dict:
    """
    Oda Ndogo (< TZS 100,000):
        Mteja analipa TZS 200 (Fixed).
        Muuzaji analipa Ada Kamili ya POS kulingana na thamani ya oda.
    Oda Kubwa (>= TZS 100,000):
        Mteja analipa ada maalum ya fixed TZS kulingana na ngazi ya kiasi
        (angalia MarketplaceFeeTier).
        Muuzaji anapata Punguzo la 50% kulingana na thamani ya oda.
    """
    threshold = Decimal("100000.00")
    is_large_order = order.total_amount >= threshold

    customer_fee = get_marketplace_customer_fee(order.total_amount)
    seller_fee = (
        get_pos_half_fee(order.total_amount)
        if is_large_order
        else get_pos_full_fee(order.total_amount)
    )

    business_wallet, _ = Wallet.objects.get_or_create(
        owner_type=Wallet.OwnerType.BUSINESS,
        business=order.store.business,
    )
    WalletTransaction.objects.create(
        kind=WalletTransaction.Kind.MARKETPLACE_FEE_SELLER,
        wallet=business_wallet,
        amount=-seller_fee,
        related_order=order,
    )
    business_wallet.balance -= seller_fee
    business_wallet.save(update_fields=["balance"])
    # Ada ya mteja (customer_fee) inarekodiwa kwa ripoti/audit - kukatwa
    # kwake halisi kunategemea payment gateway (M-Pesa/Tigo Pesa/Lipa Namba)
    # inayotumika wakati wa malipo, hivyo haihifadhiwi kwenye Wallet hapa.
    return {"customer_fee": customer_fee, "seller_fee": seller_fee}


def record_internal_ledger_transfer(cashier_wallet: Wallet, amount: Decimal, business_wallet: Wallet):
    """
    Internal Ledger Rule: Hamisho la fedha kutoka Cashier Wallet kwenda
    Business Wallet ni TZS 0 (No Network Charge) - ni muamala wa ndani
    ya database pekee, hauhusishi ada yoyote.
    """
    WalletTransaction.objects.create(
        kind=WalletTransaction.Kind.INTERNAL_TRANSFER,
        wallet=cashier_wallet, amount=-amount,
    )
    WalletTransaction.objects.create(
        kind=WalletTransaction.Kind.INTERNAL_TRANSFER,
        wallet=business_wallet, amount=amount,
    )
    cashier_wallet.balance -= amount
    cashier_wallet.save(update_fields=["balance"])
    business_wallet.balance += amount
    business_wallet.save(update_fields=["balance"])
