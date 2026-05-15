from app.schemas import TraceabilityPayload


def evaluate_rules(payload: TraceabilityPayload) -> list[str]:
    reasons: list[str] = []
    announced = max(payload.announced_weight_kg, 1e-6)
    collected = max(payload.collected_weight_kg, 1e-6)
    received = max(payload.received_weight_kg, 1e-6)
    washed = max(payload.washed_weight_kg, 1e-6)

    if (payload.collected_weight_kg - payload.announced_weight_kg) / announced > 0.4:
        reasons.append("Collected weight is more than 40% above announced weight.")
    if (payload.collected_weight_kg - payload.received_weight_kg) / collected > 0.25:
        reasons.append("Received weight is more than 25% below collected weight.")
    if (payload.received_weight_kg - payload.washed_weight_kg) / received > 0.3:
        reasons.append("Washing loss appears abnormally high.")
    if payload.edit_count >= 3:
        reasons.append("Weight values were edited repeatedly.")
    if not payload.has_photo:
        reasons.append("Photo evidence is missing.")
    if not payload.has_location_update:
        reasons.append("Location update is missing for a lot movement.")
    if payload.washed_weight_kg > 0 and payload.sold_weight_kg / washed > 1.1:
        reasons.append("Sold quantity is unexpectedly higher than washed quantity.")

    if not reasons:
        reasons.append("No critical rule violations detected.")
    return reasons


def badge_from_score(score: float) -> str:
    if score >= 0.75:
        return "High"
    if score >= 0.45:
        return "Medium"
    return "Low"


def suggested_action(score: float) -> str:
    if score >= 0.75:
        return "Hold this lot for manual verification with depot scale/photo evidence."
    if score >= 0.45:
        return "Request additional proof from collector and depot manager."
    return "Proceed but keep standard audit trail."

