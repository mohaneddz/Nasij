from fastapi import FastAPI
import numpy as np

from app.catalog import load_catalog
from app.geo_utils import haversine_km
from app.modeling import MatchingModel
from app.schemas import RecommendationItem, RecommendationPayload, RecommendationResponse

app = FastAPI(title="Matching Recommendation Service", version="0.1.0")
model = MatchingModel()


def quality_match(required: str, speciality: str) -> float:
    if required == speciality:
        return 1.0
    if required == "medium" or speciality == "medium":
        return 0.7
    return 0.4


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/recommend", response_model=RecommendationResponse)
def recommend(payload: RecommendationPayload) -> RecommendationResponse:
    catalog = load_catalog()
    subset = catalog[catalog["actor_type"] == payload.actor_type].copy()
    rows: list[RecommendationItem] = []

    for _, row in subset.iterrows():
        dist = haversine_km(payload.latitude, payload.longitude, row["lat"], row["lon"])
        capacity_ratio = min(1.0, float(row["capacity_kg"]) / max(payload.quantity_kg, 1.0))
        q_match = quality_match(payload.required_quality, row["speciality"])
        features = np.array([dist, row["reliability"], row["rating"], capacity_ratio, q_match], dtype=float)
        score = model.score(features)
        reason = f"{dist:.1f} km away, reliability {row['reliability']:.2f}, quality match {q_match:.2f}"
        rows.append(
            RecommendationItem(
                actor_id=row["actor_id"],
                actor_type=row["actor_type"],
                name=row["name"],
                distance_km=round(float(dist), 2),
                score=round(score, 4),
                reason=reason,
            )
        )

    rows.sort(key=lambda x: x.score, reverse=True)
    return RecommendationResponse(recommendations=rows[: payload.top_k])

