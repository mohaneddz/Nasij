from __future__ import annotations


def build_reply(intent: str, fields: dict[str, str | float | int | list[str] | None]) -> str:
    if intent == "create_collection_request":
        parts = ["I can prepare a collection request."]
        if fields.get("estimated_weight_kg") is not None:
            parts.append(f"Detected quantity: {fields['estimated_weight_kg']} kg.")
        if fields.get("wool_state"):
            parts.append(f"Detected state: {fields['wool_state']}.")
        if fields.get("availability"):
            parts.append(f"Availability: {fields['availability']}.")
        missing = fields.get("missing_fields") or []
        if missing:
            parts.append(f"Still needed: {', '.join(missing)}.")
        return " ".join(parts)

    if intent == "ask_route":
        return "Use the route planning service to group nearby requests and assign the depot with available capacity."
    if intent == "ask_quality":
        return "Use photo verification first, then send cleanliness/contamination scores to the quality service."
    if intent == "ask_admin_report":
        return "You can query high-loss lots by period and depot, then rank by anomaly risk score."
    return "I can help with request creation, quality checks, route suggestions, and admin summaries."

