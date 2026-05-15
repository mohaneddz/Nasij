from __future__ import annotations

from fastapi import FastAPI, File, Form, HTTPException, UploadFile

from app.modeling import WoolBoosterBundle
from app.schemas import (
    ModelInfoResponse,
    WoolClassListResponse,
    WoolPredictionResponse,
)
from app.services.prediction_service import predict_from_upload

app = FastAPI(title="Skin Health Booster Classifier Service", version="0.1.0")
bundle = WoolBoosterBundle()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/classes", response_model=WoolClassListResponse)
def classes() -> WoolClassListResponse:
    return WoolClassListResponse(classes=bundle.class_names)


@app.get("/model-info", response_model=ModelInfoResponse)
def model_info() -> ModelInfoResponse:
    return ModelInfoResponse(
        best_model_name=bundle.best_model_name,
        selection_metric=bundle.selection_metric,
        classes=bundle.class_names,
        feature_version=bundle.feature_version,
        candidates=bundle.candidates,
    )


@app.post("/predict-wool", response_model=WoolPredictionResponse)
async def predict_wool(
    file: UploadFile = File(...),
    top_k: int = Form(3),
) -> WoolPredictionResponse:
    if top_k < 1 or top_k > 10:
        raise HTTPException(status_code=400, detail="`top_k` must be between 1 and 10.")

    try:
        output = await predict_from_upload(bundle, file, top_k)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return WoolPredictionResponse(**output)
