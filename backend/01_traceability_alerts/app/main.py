from fastapi import FastAPI

from app.feature_engineering import to_feature_vector
from app.modeling import TraceabilityModel
from app.rule_engine import badge_from_score, evaluate_rules, suggested_action
from app.schemas import TraceabilityPayload, TraceabilityResponse

app = FastAPI(title="Traceability Alerts Service", version="0.1.0")
model = TraceabilityModel()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/score", response_model=TraceabilityResponse)
def score(payload: TraceabilityPayload) -> TraceabilityResponse:
    features = to_feature_vector(payload)
    ml_score = model.score(features)
    reasons = evaluate_rules(payload)
    rule_boost = 0.05 * max(0, len(reasons) - 1)
    final_score = min(1.0, max(0.0, ml_score + rule_boost))
    return TraceabilityResponse(
        risk_score=round(final_score, 4),
        risk_badge=badge_from_score(final_score),
        reasons=reasons,
        suggested_action=suggested_action(final_score),
    )

