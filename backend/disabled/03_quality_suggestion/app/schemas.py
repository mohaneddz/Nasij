from pydantic import BaseModel, Field


class QualityPayload(BaseModel):
    cleanliness_score: float = Field(ge=0, le=1)
    contamination_score: float = Field(ge=0, le=1)
    moisture_warning: bool = False
    photo_confidence: float = Field(default=0.7, ge=0, le=1)
    actor_reliability: float = Field(default=0.7, ge=0, le=1)
    declared_state: str = Field(default="raw")


class QualityResponse(BaseModel):
    quality_prediction: str
    confidence: float
    suggested_use: list[str]
    notes: list[str]

