from __future__ import annotations

from app.groq_client import chat_json

LANGS = {"en", "fr", "ar_dz", "tz"}


def translate_with_groq(text: str, source_lang: str, target_lang: str) -> tuple[str, float] | None:
    if target_lang not in LANGS:
        return None

    system = (
        "You are a strict NFN wool supply-chain translator. "
        "Always produce JSON only with keys: translated_text, confidence. "
        "Rules: preserve quantities, locations, dates, and operational terms exactly; "
        "do not add explanations; confidence must be a float in [0,1]."
    )
    user = (
        "Context: This translation is used by logistics operators, warehouse workers, and procurement teams.\n"
        "Domain terms: batch, wool, depot, washing, contamination, pickup, route, yield.\n"
        f"source_lang={source_lang}\n"
        f"target_lang={target_lang}\n"
        f"text={text}"
    )
    obj = chat_json(system, user)
    if not obj:
        return None

    translated = str(obj.get("translated_text", "")).strip()
    if not translated:
        return None
    try:
        confidence = float(obj.get("confidence", 0.8))
    except Exception:
        confidence = 0.8
    confidence = max(0.0, min(1.0, confidence))
    return translated, confidence
