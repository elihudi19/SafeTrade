"""
Bolt API Integration (Sehemu 5 ya blueprint) - STUB.

MUHIMU: Kabla ya kuwasha kipengele hiki kwa wateja halisi, LAZIMA
kuthibitishwa na Bolt kama wana public API kwa "third-party delivery
requests" (siyo Bolt rider app ya kawaida) hapa Tanzania. Bila
uthibitisho huo, tumia DeliveryOption.Kind.CUSTOM (bodaboda wa duka)
badala yake.

Muundo huu umeandaliwa ili ukishapata credentials halisi za Bolt,
unabadilisha tu mwili wa functions hizi mbili - hakuna kitu kingine
kwenye views/models kinachohitaji kubadilika.
"""
import os

import requests

BOLT_API_BASE_URL = os.environ.get("BOLT_API_BASE_URL", "")
BOLT_API_KEY = os.environ.get("BOLT_API_KEY", "")


class BoltNotConfiguredError(Exception):
    pass


def get_delivery_quote(pickup_lat, pickup_lng, dropoff_lat, dropoff_lng):
    """Inarudisha (distance_km, quoted_cost). TODO: badilisha na Bolt API halisi."""
    if not BOLT_API_KEY:
        raise BoltNotConfiguredError(
            "BOLT_API_KEY haijawekwa - tumia DeliveryOption.CUSTOM kwa sasa."
        )
    # response = requests.post(f"{BOLT_API_BASE_URL}/quotes", json={...},
    #                           headers={"Authorization": f"Bearer {BOLT_API_KEY}"})
    raise NotImplementedError("Bolt API integration inasubiri credentials halisi.")


def request_delivery(order, distance_km, quoted_cost):
    """Inatuma ombi la kuchukua mzigo kwa Bolt. TODO: badilisha na Bolt API halisi."""
    if not BOLT_API_KEY:
        raise BoltNotConfiguredError(
            "BOLT_API_KEY haijawekwa - tumia DeliveryOption.CUSTOM kwa sasa."
        )
    raise NotImplementedError("Bolt API integration inasubiri credentials halisi.")


def release_payment_to_courier(delivery_request):
    """
    SHERIA MUHIMU: Hii inaitwa PEKEE baada ya mteja kuthibitisha amepokea
    mzigo wake (views.py::confirm_delivery). Kabla ya hapo, pesa ya
    delivery HAIJAWAHI kuguswa - inabaki "imeshikiliwa" kimuundo kwa
    sababu tu haijawahi kuingizwa kwenye akaunti ya Business Wallet wala
    kutumwa kwa Bolt. Kusudi: kumzuia dereva kuchukua kazi nyingine
    badala ya kupeleka mzigo huu kwanza.

    TODO: badilisha na wito halisi wa Bolt payment-capture API mara
    itakapokuwa tayari. Kwa sasa (bila credentials), tunaweka log/return
    True ili mzunguko mzima wa confirm_delivery uweze kupimwa.
    """
    if not BOLT_API_KEY:
        # Bado hakuna muunganiko halisi wa Bolt - tunaruhusu mzunguko wa
        # confirm_delivery kuendelea (ili uweze kupima workflow), lakini
        # hii SIYO malipo halisi ya pesa kwa dereva.
        return True

    raise NotImplementedError("Bolt payment-capture API inasubiri credentials halisi.")
