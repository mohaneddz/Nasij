from pydantic import BaseModel


class WoolScore(BaseModel):
    label: str
    confidence: float


class WoolPredictionResponse(BaseModel):
    predicted_label: str
    confidence: float
    top_k: list[WoolScore]
    feature_version: str


class WoolClassListResponse(BaseModel):
    classes: list[str]


class ModelInfoResponse(BaseModel):
    best_model_name: str
    selection_metric: str
    classes: list[str]
    feature_version: str
    candidates: dict[str, dict[str, float]]

