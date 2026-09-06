from decimal import Decimal

from django.core.management.base import BaseCommand

from core.models import FeeTier, MarketplaceFeeTier


class Command(BaseCommand):
    """
    Inaweka FeeTier (ada ya Muuzaji kwenye POS) na
    MarketplaceFeeTier (ada ya Mteja kwenye Marketplace)
    kwa mujibu wa jedwali rasmi: "MCHANGANUO WA MAKATO YA SAFETRADE".

    Run: python manage.py seed_fee_tiers
    """
    help = "Inaweka FeeTier na MarketplaceFeeTier kwa namba rasmi za SafeTrade."

    def handle(self, *args, **options):
        self._seed_pos_fee_tiers()
        self._seed_marketplace_fee_tiers()

    def _seed_pos_fee_tiers(self):
        if FeeTier.objects.exists():
            self.stdout.write(self.style.WARNING(
                "FeeTier (POS) tayari zipo - sitaandika upya. "
                "Badilisha kupitia Django Admin badala yake."
            ))
            return

        # Ada Kamili ya POS (Muuzaji). Nusu Ada inakokotolewa
        # moja kwa moja kama nusu ya hizi - angalia core/services/fees.py.
        tiers = [
            (Decimal("0"), Decimal("99999.99"), Decimal("80")),
            (Decimal("100000"), Decimal("499999.99"), Decimal("100")),
            (Decimal("500000"), Decimal("999999.99"), Decimal("200")),
            (Decimal("1000000"), Decimal("4999999.99"), Decimal("500")),
            (Decimal("5000000"), Decimal("9999999.99"), Decimal("1000")),
            (Decimal("10000000"), None, Decimal("2000")),
        ]
        for min_amt, max_amt, fee in tiers:
            FeeTier.objects.create(min_amount=min_amt, max_amount=max_amt, fee_amount=fee)
        self.stdout.write(self.style.SUCCESS(
            f"FeeTier (ada ya muuzaji ya POS): tiers {len(tiers)} zimewekwa."
        ))

    def _seed_marketplace_fee_tiers(self):
        if MarketplaceFeeTier.objects.exists():
            self.stdout.write(self.style.WARNING(
                "MarketplaceFeeTier tayari zipo - sitaandika upya."
            ))
            return

        # Oda ndogo (<100k, fixed TZS 200) + Oda kubwa (100k+, tiered)
        tiers = [
            (Decimal("0"), Decimal("99999.99"), Decimal("200")),
            (Decimal("100000"), Decimal("499999.99"), Decimal("500")),
            (Decimal("500000"), Decimal("999999.99"), Decimal("1000")),
            (Decimal("1000000"), Decimal("4999999.99"), Decimal("2000")),
            (Decimal("5000000"), Decimal("9999999.99"), Decimal("2500")),
            (Decimal("10000000"), None, Decimal("2500")),
        ]
        for min_amt, max_amt, fee in tiers:
            MarketplaceFeeTier.objects.create(
                min_amount=min_amt, max_amount=max_amt, customer_fee_amount=fee
            )
        self.stdout.write(self.style.SUCCESS(
            f"MarketplaceFeeTier (ada ya mteja): tiers {len(tiers)} zimewekwa."
        ))
