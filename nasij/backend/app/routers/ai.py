from __future__ import annotations

from functools import lru_cache

from fastapi import APIRouter, File, HTTPException, UploadFile
from pydantic import BaseModel

from app.ai.forecast_data import load_time_series_frame
from app.ai.forecast_inference import ForecastPayload, ForecastResponse, run_time_series_forecast
from app.ai.image_features import extract_features
from app.ai.photo_model import PhotoVerifierModel
from app.ai.photo_checks import (
    blur_score_from_features,
    classify_wool_condition,
    guess_photo_type,
    review_notes,
)

router = APIRouter(prefix="/ai", tags=["ai"])


@lru_cache(maxsize=1)
def _series_df():
    return load_time_series_frame()


@lru_cache(maxsize=1)
def _photo_model():
    return PhotoVerifierModel()


class PhotoVerificationResponse(BaseModel):
    is_wool: bool
    wool_condition: str
    photo_type: str
    confidence: float
    blur_score: float
    brightness: float
    needs_human_review: bool
    notes: list[str]


class ServiceInfoResponse(BaseModel):
    service: str
    data_source: str
    observations: int
    first_year: int
    last_year: int
    columns: list[str]


# ── Forecasting ────────────────────────────────────────


@router.get("/forecast/info", response_model=ServiceInfoResponse)
def forecast_info() -> ServiceInfoResponse:
    df = _series_df()
    return ServiceInfoResponse(
        service="demand_forecasting",
        data_source="Synthetic Algerian demand built from Table 28 USA imports/exports with Eid shock",
        observations=int(len(df)),
        first_year=int(df["year"].iloc[0]),
        last_year=int(df["year"].iloc[-1]),
        columns=list(df.columns),
    )


@router.post("/forecast", response_model=ForecastResponse)
def forecast(payload: ForecastPayload) -> ForecastResponse:
    try:
        output = run_time_series_forecast(_series_df(), payload)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return ForecastResponse(**output)


@router.post("/forecast/next-year")
def forecast_next_year() -> dict:
    output = run_time_series_forecast(_series_df(), ForecastPayload(horizon_years=1))
    return output["forecast"][0]


# ── Photo Verification ─────────────────────────────────


@router.post("/verify-photo", response_model=PhotoVerificationResponse)
async def verify_photo(file: UploadFile = File(...)) -> PhotoVerificationResponse:
    image_bytes = await file.read()
    features = extract_features(image_bytes)
    is_wool, confidence = _photo_model().predict(features)

    blur = blur_score_from_features(features)
    photo_type = guess_photo_type(features)
    wool_condition, condition_notes = classify_wool_condition(
        features,
        is_wool=is_wool,
        confidence=confidence,
        blur_score=blur,
    )
    notes = condition_notes + review_notes(features, confidence)
    needs_review = (confidence < 0.6) or (blur < 0.3)

    return PhotoVerificationResponse(
        is_wool=is_wool,
        wool_condition=wool_condition,
        photo_type=photo_type,
        confidence=round(confidence, 4),
        blur_score=blur,
        brightness=round(float(features[0]), 4),
        needs_human_review=needs_review,
        notes=notes,
    )
