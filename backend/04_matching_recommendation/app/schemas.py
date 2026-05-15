from pydantic import BaseModel, Field


class RecommendationPayload(BaseModel):
    latitude: float
    longitude: float
    quantity_kg: float = Field(gt=0)
    required_quality: str = "medium"
    actor_type: str = "depot"
    top_k: int = Field(default=3, ge=1, le=10)


class RecommendationItem(BaseModel):
    actor_id: str
    actor_type: str
    name: str
    distance_km: float
    score: float
    reason: str


class RecommendationResponse(BaseModel):
    recommendations: list[RecommendationItem]

