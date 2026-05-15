from __future__ import annotations

from fastapi import FastAPI, File, Form, HTTPException, UploadFile

from app.modeling import WoolModelBundle
from app.schemas import WoolClassListResponse, WoolPredictionResponse
from app.services.prediction_service import predict_from_upload

app = FastAPI(title="Wool on Skin classifier", version="0.2.0")
bundle = WoolModelBundle()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/classes", response_model=WoolClassListResponse)
def classes() -> WoolClassListResponse:
    return WoolClassListResponse(classes=bundle.class_names)


@app.post("/predict-wool", response_model=WoolPredictionResponse)
async def predict_wool(
    file: UploadFile = File(...),
    top_k: int = Form(2),
) -> WoolPredictionResponse:
    if top_k < 1 or top_k > 10:
        raise HTTPException(status_code=400, detail="`top_k` must be between 1 and 10.")

    try:
        output = await predict_from_upload(bundle, file, top_k)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return WoolPredictionResponse(**output)
