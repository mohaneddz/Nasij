from fastapi import FastAPI

from app.features import suggested_use, to_vector
from app.modeling import QualityModel
from app.schemas import QualityPayload, QualityResponse

app = FastAPI(title="Quality Suggestion Service", version="0.1.0")
model = QualityModel()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/predict-quality", response_model=QualityResponse)
def predict_quality(payload: QualityPayload) -> QualityResponse:
    x = to_vector(payload)
    label, confidence = model.predict(x)
    notes = []
    if payload.moisture_warning:
        notes.append("Moisture warning present; consider extra drying before transformation.")
    if payload.contamination_score > 0.35:
        notes.append("Contamination appears elevated; sorting is recommended.")
    if not notes:
        notes.append("No major quality blockers detected.")
    return QualityResponse(
        quality_prediction=label,
        confidence=round(confidence, 4),
        suggested_use=suggested_use(label),
        notes=notes,
    )

