from pydantic import BaseModel


class BreedScore(BaseModel):
    breed: str
    confidence: float


class BreedPredictionResponse(BaseModel):
    predicted_breed: str
    confidence: float
    top_k: list[BreedScore]
    feature_version: str


class BreedListResponse(BaseModel):
    breeds: list[str]
