from fastapi import FastAPI, File, UploadFile

from app.image_features import extract_features
from app.modeling import PhotoVerifierModel
from app.photo_checks import (
    blur_score_from_features,
    classify_wool_condition,
    guess_photo_type,
    review_notes,
)
from app.schemas import PhotoVerificationResponse

app = FastAPI(title="Photo Verification Service", version="0.1.0")
model = PhotoVerifierModel()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/verify", response_model=PhotoVerificationResponse)
async def verify_photo(file: UploadFile = File(...)) -> PhotoVerificationResponse:
    image_bytes = await file.read()
    features = extract_features(image_bytes)
    is_wool, confidence = model.predict(features)

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
