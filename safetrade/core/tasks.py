"""
Celery background tasks - Sehemu 3 & 4 za blueprint.
Kazi hizi zinatembea kwenye 'safetrade-celery-worker' service (angalia
render.yaml) - process TOFAUTI na web server, kwa hiyo haziathiri
uzoefu wa mtumiaji anayekata risiti.
"""
from celery import shared_task
from django.utils import timezone

from . import models
from .services.sms import send_sms
from .services.predictive_analytics import run_predictive_analytics


@shared_task
def resend_pending_digital_receipts():
    """
    'Tena SMS ya Online (Auto Resend)' - Sehemu 3.
    Inatafuta risiti zilizokatwa offline ambazo bado hazijatumiwa
    SMS/WhatsApp, na kuzituma sasa network ikiwa imerudi.
    """
    pending = models.Receipt.objects.filter(
        created_offline=True, sms_or_softcopy_sent=False
    ).exclude(customer_phone="")
    count = 0
    for receipt in pending:
        message = (
            f"SafeTrade: Risiti yako ya TZS {receipt.total_amount} "
            f"imethibitishwa. Asante kwa kununua."
        )
        if send_sms(receipt.customer_phone, message):
            receipt.sms_or_softcopy_sent = True
            receipt.save(update_fields=["sms_or_softcopy_sent"])
            count += 1
    return f"Processed {count} receipts"


@shared_task
def compute_predictive_alerts():
    """
    Utabiri wa Akiba (Sehemu 4) - v2: sales velocity, trend, siku-hadi-
    kuisha-stock, na kiasi kinachopendekezwa cha kuagiza. Angalia
    core/services/predictive_analytics.py kwa mantiki kamili.
    """
    alerts_written = run_predictive_analytics()
    return f"Predictive alerts updated: {alerts_written} alert(s) evaluated"
