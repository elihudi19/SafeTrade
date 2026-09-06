"""
Costing Engine - "kila mzigo unapoingia Stoo, gharama halisi ijulikane."

Huduma hii inashughulikia:
1. Kuandika StockIntake (mzigo mpya) - ikiwa ni bundle/kifungu, inakokotoa
   bei ya kipande kimoja kiotomatiki.
2. Kusasisha Product.cost_price (bei ya ununuzi ya sasa - "last cost"
   method, ndiyo njia rahisi na inayoeleweka zaidi kwa maduka madogo).
3. Kuongeza ShelfStock ya Warehouse kwa idadi iliyoletwa.
4. Kukokotoa suggested_min_selling_price - bei ya chini kabisa ili
   mzigo huu usilete hasara (haihusishi bei ya kuuzia halisi - hiyo
   bado ni uamuzi wa Mmiliki/Cashier, hii ni PENDEKEZO la kiuchambuzi tu).
"""
from decimal import Decimal

from django.db import transaction

from core.models import StockIntake, Product, ShelfStock, Store


def compute_unit_cost_price(quantity_received, is_bundle_purchase, units_per_bundle,
                             bundle_cost_price, unit_cost_price_input):
    """
    Kama ni ununuzi wa bundle/kifungu: bei ya kipande = bundle_cost_price / units_per_bundle.
    Vinginevyo: unit_cost_price_input inatumika moja kwa moja.
    """
    if is_bundle_purchase:
        if not bundle_cost_price or units_per_bundle <= 0:
            raise ValueError(
                "Kwa ununuzi wa bundle/kifungu, bundle_cost_price na "
                "units_per_bundle (zaidi ya sifuri) ni lazima."
            )
        return (bundle_cost_price / units_per_bundle).quantize(Decimal("0.01"))
    if unit_cost_price_input is None:
        raise ValueError("unit_cost_price ni lazima kama siyo ununuzi wa bundle.")
    return Decimal(str(unit_cost_price_input))


@transaction.atomic
def record_stock_intake(*, store: Store, product: Product, quantity_received: int,
                         is_bundle_purchase: bool, units_per_bundle: int,
                         bundle_cost_price, unit_cost_price, transport_cost: Decimal,
                         other_costs: Decimal, recorded_by) -> StockIntake:
    """
    Kuandika mzigo mpya - hii ndiyo NJIA PEKEE inayopaswa kutumika
    kuongeza stock kwenye Warehouse (badala ya kubadilisha ShelfStock
    moja kwa moja), ili gharama halisi isikosekane kamwe.
    """
    computed_unit_cost = compute_unit_cost_price(
        quantity_received, is_bundle_purchase, units_per_bundle,
        bundle_cost_price, unit_cost_price,
    )

    goods_cost = computed_unit_cost * quantity_received
    total_cost = goods_cost + transport_cost + other_costs
    suggested_min_price = (total_cost / quantity_received).quantize(Decimal("0.01"))

    intake = StockIntake.objects.create(
        store=store, product=product, quantity_received=quantity_received,
        is_bundle_purchase=is_bundle_purchase, units_per_bundle=units_per_bundle,
        bundle_cost_price=bundle_cost_price, unit_cost_price=computed_unit_cost,
        transport_cost=transport_cost, other_costs=other_costs,
        total_cost=total_cost, suggested_min_selling_price=suggested_min_price,
        recorded_by=recorded_by,
    )

    # Product.cost_price inasasishwa na bei ya MZIGO WA MWISHO ("last cost")
    # - njia rahisi na ya kueleweka zaidi kwa maduka madogo, badala ya
    # weighted-average inayohitaji ufuatiliaji wa ziada wa stock lots.
    product.cost_price = computed_unit_cost
    product.save(update_fields=["cost_price"])

    warehouse_stock, _ = ShelfStock.objects.select_for_update().get_or_create(
        store=store, product=product,
        location_type=ShelfStock.LocationType.WAREHOUSE, shelf_code="",
        defaults={"quantity": 0},
    )
    warehouse_stock.quantity += quantity_received
    warehouse_stock.save(update_fields=["quantity"])

    return intake
