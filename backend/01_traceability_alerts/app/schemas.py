from pydantic import BaseModel, Field


class TraceabilityPayload(BaseModel):
    announced_weight_kg: float = Field(ge=0)
    collected_weight_kg: float = Field(ge=0)
    received_weight_kg: float = Field(ge=0)
    washed_weight_kg: float = Field(ge=0)
    transformed_weight_kg: float = Field(ge=0)
    sold_weight_kg: float = Field(ge=0)
    edit_count: int = Field(ge=0, default=0)
    has_photo: bool = True
    has_location_update: bool = True
    actor_history_risk: float = Field(default=0.2, ge=0, le=1)


class TraceabilityResponse(BaseModel):
    risk_score: float
    risk_badge: str
    reasons: list[str]
    suggested_action: str

