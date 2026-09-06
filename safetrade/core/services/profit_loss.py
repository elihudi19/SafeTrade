"""
Profit & Loss Engine.

Sehemu mbili kuu:
1. apply_receipt_costing(receipt) - inaitwa MARA MOJA risiti inapoundwa,
   inanasa cost_price_snapshot ya kila ReceiptItem na kukokotoa
   Receipt.total_cost_of_goods / gross_profit papo hapo (siyo baadaye kwa
   batch job - hii inahakikisha ripoti za "leo" ni sahihi papo hapo).
2. get_profit_loss_report(store, period) - ripoti kamili ya faida/hasara
   kwa kipindi (leo/wiki/mwezi), ikijumuisha mapato, gharama za bidhaa
   (COGS), gharama za uendeshaji (Expense - usafiri ukitengwa pekee kwa
   mujibu wa maombi), na faida/hasara halisi (net).
"""
from datetime import date, timedelta
from decimal import Decimal

from django.db.models import Sum
from django.utils import timezone

from core.models import Receipt, ReceiptItem, Expense, StockIntake


def apply_receipt_costing(receipt) -> None:
    """
    Inanasa cost_price ya kila bidhaa WAKATI HUO (snapshot) na kuhesabu
    COGS + gross profit ya risiti nzima. LAZIMA iitwe BAADA YA
    ReceiptItem zote kuundwa (angalia views.py).
    """
    total_cost = Decimal("0.00")
    items = receipt.items.select_related("product").all()
    for item in items:
        if not item.cost_price_snapshot:
            item.cost_price_snapshot = item.product.cost_price
            item.save(update_fields=["cost_price_snapshot"])
        total_cost += item.cost_price_snapshot * item.quantity

    receipt.total_cost_of_goods = total_cost
    receipt.gross_profit = receipt.total_amount - total_cost
    receipt.save(update_fields=["total_cost_of_goods", "gross_profit"])


def _period_bounds(period: str, reference_date: date | None = None):
    reference_date = reference_date or timezone.now().date()
    if period == "daily":
        start = reference_date
    elif period == "weekly":
        start = reference_date - timedelta(days=reference_date.weekday())
    elif period == "monthly":
        start = reference_date.replace(day=1)
    else:
        raise ValueError("period lazima iwe 'daily', 'weekly', au 'monthly'.")
    return start, reference_date


def get_profit_loss_report(store, period: str = "daily", reference_date: date | None = None) -> dict:
    start, end = _period_bounds(period, reference_date)

    receipts = Receipt.objects.filter(
        store=store, created_at__date__gte=start, created_at__date__lte=end,
    )
    revenue = receipts.aggregate(t=Sum("total_amount"))["t"] or Decimal("0")
    cogs = receipts.aggregate(t=Sum("total_cost_of_goods"))["t"] or Decimal("0")
    gross_profit = revenue - cogs

    expenses = Expense.objects.filter(
        store=store, expense_date__gte=start, expense_date__lte=end,
    )
    transport_expenses = expenses.filter(
        category=Expense.Category.TRANSPORT
    ).aggregate(t=Sum("amount"))["t"] or Decimal("0")
    other_expenses = expenses.exclude(
        category=Expense.Category.TRANSPORT
    ).aggregate(t=Sum("amount"))["t"] or Decimal("0")

    # Gharama za usafiri za MIZIGO (StockIntake.transport_cost) zinaongezwa
    # kwenye jumla ya "transport" - hizi ni tofauti na Expense za jumla
    # (mfano gharama za usafiri wa kila siku wa mfanyakazi), lakini zote
    # ni "usafiri" kwa ripoti - zimetengwa PEKEE dhidi ya gharama nyingine
    # kwa mujibu wa maombi yako.
    intake_transport = StockIntake.objects.filter(
        store=store, created_at__date__gte=start, created_at__date__lte=end,
    ).aggregate(t=Sum("transport_cost"))["t"] or Decimal("0")
    intake_other = StockIntake.objects.filter(
        store=store, created_at__date__gte=start, created_at__date__lte=end,
    ).aggregate(t=Sum("other_costs"))["t"] or Decimal("0")

    total_transport = transport_expenses + intake_transport
    total_other_expenses = other_expenses + intake_other
    total_operating_expenses = total_transport + total_other_expenses

    net_profit = gross_profit - total_operating_expenses

    return {
        "period": period,
        "start_date": str(start),
        "end_date": str(end),
        "revenue": revenue,
        "cost_of_goods_sold": cogs,
        "gross_profit": gross_profit,
        "transport_expenses": total_transport,
        "other_operating_expenses": total_other_expenses,
        "total_operating_expenses": total_operating_expenses,
        "net_profit": net_profit,
        "is_loss": net_profit < 0,
        "receipt_count": receipts.count(),
    }


def get_daily_net_profit_series(store, days: int = 30) -> list[dict]:
    """
    Inarudisha orodha ya (tarehe, net_profit) kwa siku `days` zilizopita -
    msingi wa utabiri wa mwenendo wa faida/hasara (Predictive Analytics).
    """
    today = timezone.now().date()
    series = []
    for i in range(days - 1, -1, -1):
        day = today - timedelta(days=i)
        report = get_profit_loss_report(store, period="daily", reference_date=day)
        series.append({"date": str(day), "net_profit": report["net_profit"]})
    return series
