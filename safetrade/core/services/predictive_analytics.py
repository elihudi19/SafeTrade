"""
Predictive Analytics Engine (v2) - Utabiri wa Akiba.

Toleo hili SIYO tena "je, mauzo ya wiki hii yamezidi reorder_level?" tu -
ni mfumo halisi wa reorder-point wenye:

1. **Mwendo wa mauzo (sales velocity)** - wastani wa mauzo ya kila siku
   kwa dirisha mbili tofauti (siku 7 na siku 30) ili kuona kasi ya sasa
   dhidi ya kasi ya muda mrefu.
2. **Mwenendo (trend)** - asilimia ya ongezeko/upungufu wa kasi ya
   wiki ya karibuni ikilinganishwa na wastani wa mwezi - hii ndiyo
   "predictive" ya kweli: inaonyesha kama bidhaa inaharakisha kuuzwa
   HATA KAMA bado haijafika reorder_level.
3. **Siku-hadi-kuisha-stock (days until stockout)** - kutumia kasi ya
   sasa kukadiria ni lini stock itaisha, si tu "chini ya X vipande".
4. **Lead time ya bidhaa (Product.lead_time_days)** - alert ya
   "fast_moving/reorder" inatolewa mapema iwapo stock itaisha KABLA
   mzigo mpya haujafika (badala ya kusubiri stock ifike sifuri).
5. **Kiasi kinachopendekezwa cha kuagiza (suggested_reorder_quantity)** -
   siyo tu "agiza", bali "agiza kiasi gani" kwa kutumia kasi ya sasa na
   lead time (na kizio cha usalama cha 1.5x).
6. **Bidhaa za polepole (slow-moving)** zinatambuliwa kwa njia mbili:
   hazijauzwa kabisa kwa siku 30, AU zina stock ya ziada isiyolingana na
   kasi ya mauzo (>60 siku za stock zilizosimama - fedha zimefungwa).

Alerts zinahesabiwa upya kila run (update_or_create) ili detail_json
ibaki ya kisasa - siyo kuandikwa mara moja tu na kusahaulika.
"""
import math
from decimal import Decimal

from django.db.models import Sum
from django.utils import timezone

from core.models import PredictiveAlert, Product, ReceiptItem, ShelfStock

SLOW_MOVING_NO_SALE_DAYS = 30
SLOW_MOVING_EXCESS_STOCK_DAYS = 60
SAFETY_STOCK_MULTIPLIER = Decimal("1.5")


def _sold_quantity(product_id, store_id, since):
    return ReceiptItem.objects.filter(
        product_id=product_id,
        receipt__store_id=store_id,
        receipt__created_at__gte=since,
    ).aggregate(t=Sum("quantity"))["t"] or 0


def compute_metrics_for_store_product(store_id, product: Product, now=None):
    """
    Inarudisha dict kamili ya metrics za bidhaa fulani kwenye duka fulani -
    hii ndiyo "ubongo" wa predictive engine, imetenganishwa na
    kuandika-database ili iweze kupimwa (unit tested) peke yake.
    """
    now = now or timezone.now()
    last_30 = now - timezone.timedelta(days=30)
    last_7 = now - timezone.timedelta(days=7)

    sold_30d = _sold_quantity(product.id, store_id, last_30)
    sold_7d = _sold_quantity(product.id, store_id, last_7)

    avg_daily_30d = sold_30d / 30
    avg_daily_7d = sold_7d / 7

    current_stock = ShelfStock.objects.filter(
        store_id=store_id, product=product
    ).aggregate(t=Sum("quantity"))["t"] or 0

    trend_percent = None
    if avg_daily_30d > 0:
        trend_percent = round(((avg_daily_7d - avg_daily_30d) / avg_daily_30d) * 100, 1)

    # Tunatumia kasi ya wiki ya karibuni kwa utabiri (inabadilika haraka
    # zaidi kuliko wastani wa mwezi) - ikiwa hakuna mauzo wiki hii,
    # tunarudi kwenye wastani wa mwezi ili tusipoteze ishara kabisa.
    velocity_for_prediction = avg_daily_7d if avg_daily_7d > 0 else avg_daily_30d

    days_until_stockout = None
    if velocity_for_prediction > 0:
        days_until_stockout = round(current_stock / velocity_for_prediction, 1)

    return {
        "current_stock": current_stock,
        "sold_last_7_days": sold_7d,
        "sold_last_30_days": sold_30d,
        "avg_daily_sales_7d": round(avg_daily_7d, 2),
        "avg_daily_sales_30d": round(avg_daily_30d, 2),
        "trend_percent_week_vs_month": trend_percent,
        "days_until_stockout": days_until_stockout,
        "velocity_used_for_prediction": round(velocity_for_prediction, 2),
        "lead_time_days": product.lead_time_days,
        "reorder_level": product.reorder_level,
    }


def _suggested_reorder_quantity(metrics: dict) -> int:
    velocity = metrics["velocity_used_for_prediction"]
    lead_time = metrics["lead_time_days"]
    if velocity <= 0:
        # Hakuna data ya kutosha ya mauzo - rudi kwenye reorder_level
        # tuli kama pendekezo la chini kabisa (better than nothing).
        return metrics["reorder_level"] or 0
    return math.ceil(Decimal(str(velocity)) * lead_time * SAFETY_STOCK_MULTIPLIER)


def evaluate_alerts(metrics: dict) -> list[dict]:
    """
    Inaamua ni alert zipi zinastahili kutolewa kwa mujibu wa metrics
    zilizokokotolewa - PURE FUNCTION (hakuna database write hapa),
    hivyo inaweza kupimwa moja kwa moja na majaribio (unit tests).
    """
    alerts = []

    breach_static_threshold = (
        metrics["reorder_level"] > 0 and metrics["current_stock"] <= metrics["reorder_level"]
    )
    breach_predicted_stockout = (
        metrics["days_until_stockout"] is not None
        and metrics["days_until_stockout"] <= metrics["lead_time_days"]
    )

    if breach_static_threshold or breach_predicted_stockout:
        if breach_predicted_stockout and not breach_static_threshold:
            reason = "predicted_stockout_before_restock_arrives"
        elif breach_static_threshold and not breach_predicted_stockout:
            reason = "below_manual_reorder_level"
        else:
            reason = "below_manual_reorder_level_and_predicted_stockout"

        alerts.append({
            "alert_type": PredictiveAlert.AlertType.FAST_MOVING,
            "detail_json": {
                **metrics,
                "reason": reason,
                "suggested_reorder_quantity": _suggested_reorder_quantity(metrics),
            },
        })

    no_sales_30d = metrics["sold_last_30_days"] == 0
    days_of_stock_at_current_pace = (
        (metrics["current_stock"] / metrics["avg_daily_sales_30d"])
        if metrics["avg_daily_sales_30d"] > 0 else None
    )
    excess_stock = (
        days_of_stock_at_current_pace is not None
        and days_of_stock_at_current_pace > SLOW_MOVING_EXCESS_STOCK_DAYS
    )

    if metrics["current_stock"] > 0 and (no_sales_30d or excess_stock):
        alerts.append({
            "alert_type": PredictiveAlert.AlertType.SLOW_MOVING,
            "detail_json": {
                **metrics,
                "days_of_stock_at_current_pace": (
                    round(days_of_stock_at_current_pace, 1)
                    if days_of_stock_at_current_pace is not None else None
                ),
                "reason": (
                    f"no_sales_in_last_{SLOW_MOVING_NO_SALE_DAYS}_days" if no_sales_30d
                    else "excess_stock_vs_current_demand"
                ),
            },
        })

    return alerts


def run_predictive_analytics() -> int:
    """
    Inapitia KILA mchanganyiko wa (store, product) ambao KWELI una stock
    iliyorekodiwa (badala ya kila store ya business bila kujali kama
    inauza bidhaa hiyo - hii inazuia "noise alerts" zisizo na maana).
    Inaita Celery Beat kila masaa 6 (config/settings.py).
    """
    now = timezone.now()
    combos = ShelfStock.objects.values_list("store_id", "product_id").distinct()
    products_by_id = {p.id: p for p in Product.objects.all()}

    alerts_written = 0
    for store_id, product_id in combos:
        product = products_by_id.get(product_id)
        if not product:
            continue

        metrics = compute_metrics_for_store_product(store_id, product, now=now)
        for alert in evaluate_alerts(metrics):
            PredictiveAlert.objects.update_or_create(
                store_id=store_id, product=product,
                alert_type=alert["alert_type"], acknowledged=False,
                defaults={"detail_json": alert["detail_json"]},
            )
            alerts_written += 1

    alerts_written += run_business_trend_analytics()
    return alerts_written


# =============================================================================
# UTABIRI WA MWENENDO WA BIASHARA (Faida/Hasara) - "je, tunaelekea hasara?"
# =============================================================================

LOSS_TREND_MULTIPLIER_WARNING_DAYS = 7  # tunaangalia wastani wa siku 7 za karibuni


def compute_business_trend_metrics(store, days: int = 30) -> dict:
    """
    Inatumia mfululizo wa faida/hasara ya kila siku (siku 30 zilizopita)
    kuona kama biashara INAELEKEA hasara au faida - hii ndiyo "predictive"
    ya kweli ya kifedha, siyo tu "leo tumepata hasara".
    """
    from .profit_loss import get_daily_net_profit_series

    series = get_daily_net_profit_series(store, days=days)
    values = [Decimal(str(day["net_profit"])) for day in series]

    last_7 = values[-LOSS_TREND_MULTIPLIER_WARNING_DAYS:]
    avg_last_7 = sum(last_7) / len(last_7) if last_7 else Decimal("0")
    avg_last_30 = sum(values) / len(values) if values else Decimal("0")

    trend_percent = None
    if avg_last_30 != 0:
        trend_percent = round(float((avg_last_7 - avg_last_30) / abs(avg_last_30)) * 100, 1)

    projected_monthly_profit = avg_last_7 * 30

    return {
        "daily_net_profit_series": series,
        "average_daily_profit_last_7_days": round(float(avg_last_7), 2),
        "average_daily_profit_last_30_days": round(float(avg_last_30), 2),
        "trend_percent_week_vs_month": trend_percent,
        "projected_monthly_profit_at_current_pace": round(float(projected_monthly_profit), 2),
    }


def evaluate_business_trend_alert(metrics: dict) -> dict | None:
    """
    PURE FUNCTION: inaamua kama biashara inastahili LOSS_WARNING au
    PROFIT_TREND kwa mujibu wa metrics za faida/hasara.
    """
    avg_7 = metrics["average_daily_profit_last_7_days"]

    if avg_7 < 0:
        return {
            "alert_type": PredictiveAlert.AlertType.LOSS_WARNING,
            "detail_json": {
                **metrics,
                "reason": "negative_average_daily_profit_last_7_days",
                "recommendation": (
                    "Wastani wa faida ya siku 7 za karibuni ni HASARA. Angalia "
                    "gharama za uendeshaji (Expense) na bei za kuuzia - huenda "
                    "bei za sasa ziko chini ya gharama halisi za mzigo."
                ),
            },
        }

    # Faida chanya - bado tunatoa alert ya taarifa (siyo onyo) ili Owner
    # aone mwenendo, hasa kama unashuka kwa kasi (trend hasi kubwa) hata
    # ikiwa bado ni chanya.
    return {
        "alert_type": PredictiveAlert.AlertType.PROFIT_TREND,
        "detail_json": {
            **metrics,
            "reason": "positive_average_daily_profit",
        },
    }


def run_business_trend_analytics() -> int:
    """Inakokotoa mwenendo wa faida/hasara kwa kila Store na kuandika alert moja kwa kila duka."""
    from core.models import Store

    written = 0
    for store in Store.objects.filter(is_active=True):
        metrics = compute_business_trend_metrics(store)
        alert = evaluate_business_trend_alert(metrics)
        if alert:
            PredictiveAlert.objects.update_or_create(
                store=store, product=None, alert_type=alert["alert_type"], acknowledged=False,
                defaults={"detail_json": alert["detail_json"]},
            )
            written += 1
    return written
