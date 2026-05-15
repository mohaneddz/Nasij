from __future__ import annotations

from fastapi import FastAPI, File, Form, HTTPException, UploadFile

from app.modeling import SheepModelBundle
from app.schemas import BreedListResponse, BreedPredictionResponse
from app.services.prediction_service import predict_from_upload

app = FastAPI(title="Sheep Breed Classifier Service", version="0.1.0")
bundle = SheepModelBundle()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/breeds", response_model=BreedListResponse)
def breeds() -> BreedListResponse:
    return BreedListResponse(breeds=bundle.breed_names)


@app.post("/predict-breed", response_model=BreedPredictionResponse)
async def predict_breed(
    file: UploadFile = File(...),
    top_k: int = Form(3),
) -> BreedPredictionResponse:
    if top_k < 1 or top_k > 10:
        raise HTTPException(status_code=400, detail="`top_k` must be between 1 and 10.")

    try:
        output = await predict_from_upload(bundle, file, top_k)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return BreedPredictionResponse(**output)
