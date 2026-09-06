"""
SMS Gateway - stub. Kwa uzalishaji halisi, unganisha na mtoa huduma
(Beem Africa, Africa's Talking, n.k.) hapa - Branded Sender ID "SafeTrade"
kama ilivyoainishwa kwenye blueprint (Sehemu 3).

Kwa sasa (bila credentials halisi), send_sms() inaweka LOG pekee ili
workflow nzima (OTP, digital receipts) iweze kupimwa bila gharama za SMS
halisi.
"""
import logging
import os

logger = logging.getLogger("safetrade.sms")

SMS_API_KEY = os.environ.get("SMS_API_KEY", "")
SMS_SENDER_ID = os.environ.get("SMS_SENDER_ID", "SafeTrade")


def send_sms(phone_number: str, message: str) -> bool:
    if not SMS_API_KEY:
        logger.info("[SMS-STUB] Kwenda %s kutoka %s: %s", phone_number, SMS_SENDER_ID, message)
        return True

    # TODO: badilisha na muunganiko halisi wa SMS gateway (mfano Beem):
    # requests.post(SMS_PROVIDER_URL, json={...}, headers={...})
    raise NotImplementedError("SMS gateway halisi inasubiri credentials.")
