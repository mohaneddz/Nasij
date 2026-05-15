from __future__ import annotations

from app.groq_client import chat_json

ALLOWED_INTENTS = {
    "create_collection_request",
    "ask_route",
    "ask_quality",
    "ask_admin_report",
    "fallback",
}


def assist_with_groq(message: str) -> dict[str, object] | None:
    system = (
        "You are a strict JSON assistant for a wool supply chain app. "
        "Return only a JSON object with keys: intent, confidence, extracted_fields, reply. "
        "intent must be one of: create_collection_request, ask_route, ask_quality, ask_admin_report, fallback. "
        "extracted_fields must contain keys: estimated_weight_kg, sheep_count, wool_state, availability, missing_fields."
    )
    user = f"User message: {message}"
    obj = chat_json(system, user)
    if not obj:
        return None

    intent = str(obj.get("intent", "fallback"))
    if intent not in ALLOWED_INTENTS:
        intent = "fallback"

    try:
        confidence = float(obj.get("confidence", 0.7))
    except Exception:
        confidence = 0.7
    confidence = max(0.0, min(1.0, confidence))

    extracted = obj.get("extracted_fields")
    if not isinstance(extracted, dict):
        extracted = {
            "estimated_weight_kg": None,
            "sheep_count": None,
            "wool_state": None,
            "availability": None,
            "missing_fields": ["location", "photos"],
        }

    reply = str(obj.get("reply", "I can help with collection requests, quality checks, routes, and reports."))

    return {
        "intent": intent,
        "confidence": confidence,
        "extracted_fields": extracted,
        "reply": reply,
        "backend": "groq_api",
    }
