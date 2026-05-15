from pydantic import BaseModel


class PhotoVerificationResponse(BaseModel):
    is_wool: bool
    wool_condition: str
    photo_type: str
    confidence: float
    blur_score: float
    brightness: float
    needs_human_review: bool
    notes: list[str]
