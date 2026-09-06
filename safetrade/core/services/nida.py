"""
NIDA API Integration - kuthibitisha kuwa namba ya simu aliyotoa Owner
wakati wa kujisajili imesajiliwa rasmi kwa NIDA namba (Number ya Kitambulisho
cha Taifa) aliyotoa.

MUHIMU: Hii ni sehemu MPYA badala ya "kupakia Leseni ya Biashara" - Owner
sasa anathibitishwa kwa NIDA + OTP badala ya hati ya leseni.

Kwa vile huna credentials halisi za NIDA API bado, tumeweka NIDA_MOCK_MODE
(imewashwa kwa default kwenye .env.example ya local dev) ili uweze kupima
mfumo mzima (register -> verify -> OTP) bila kuwa na muunganiko wa kweli
wa NIDA. UZIME (NIDA_MOCK_MODE=False) na weka NIDA_API_KEY halisi kabla
ya kwenda live na wateja halisi - vinginevyo Owner yeyote ataweza
"kuthibitishwa" bila ukaguzi halisi.
"""
import os
import re

import requests

NIDA_API_BASE_URL = os.environ.get("NIDA_API_BASE_URL", "")
NIDA_API_KEY = os.environ.get("NIDA_API_KEY", "")
NIDA_MOCK_MODE = os.environ.get("NIDA_MOCK_MODE", "True") == "True"


class NIDANotConfiguredError(Exception):
    pass


class NIDAMismatchError(Exception):
    """Namba ya simu haiendani na rekodi za NIDA kwa nida_number husika."""
    pass


def _basic_format_valid(nida_number: str, phone_number: str) -> bool:
    nida_ok = bool(re.fullmatch(r"\d{8}-\d{5}-\d{5}-\d{2}", nida_number)) or bool(
        re.fullmatch(r"\d{20}", nida_number.replace("-", ""))
    )
    phone_ok = bool(re.fullmatch(r"(\+255|0)[67]\d{8}", phone_number))
    return nida_ok and phone_ok


def verify_identity(nida_number: str, phone_number: str) -> bool:
    """
    Inarudisha True kama namba ya simu imesajiliwa rasmi kwa NIDA namba
    husika, False kama HAILINGANI (mismatch).

    NIDA_MOCK_MODE=True (default ya dev): inakagua muundo wa namba pekee
    (siyo uhalisia dhidi ya NIDA halisi) - kwa ajili ya kupima workflow
    nzima ya register/OTP bila muunganiko wa kweli.
    """
    if NIDA_MOCK_MODE:
        return _basic_format_valid(nida_number, phone_number)

    if not NIDA_API_KEY or not NIDA_API_BASE_URL:
        raise NIDANotConfiguredError(
            "NIDA_API_KEY/NIDA_API_BASE_URL hazijawekwa. Weka NIDA_MOCK_MODE=True "
            "kwa ajili ya majaribio ya ndani, au weka credentials halisi za NIDA "
            "kabla ya kwenda live."
        )

    # TODO: badilisha na muundo halisi wa NIDA API mara utakapopata
    # credentials na nyaraka za integration kutoka NIDA.
    # response = requests.post(
    #     f"{NIDA_API_BASE_URL}/verify",
    #     json={"nida_number": nida_number, "phone_number": phone_number},
    #     headers={"Authorization": f"Bearer {NIDA_API_KEY}"},
    #     timeout=15,
    # )
    # response.raise_for_status()
    # return response.json().get("match", False)
    raise NotImplementedError("NIDA API integration inasubiri credentials na nyaraka halisi.")
