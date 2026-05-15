from __future__ import annotations

from pydantic import BaseModel, Field


class ForecastPayload(BaseModel):
    horizon_years: int = Field(default=1, ge=1, le=10)
    lookback_years: int = Field(default=15, ge=5, le=60)


class ForecastPoint(BaseModel):
    year: int
    demand_kg: float


class ForecastResponse(BaseModel):
    forecast_type: str
    horizon_years: int
    lookback_years: int
    last_historical_year: int
    confidence: float
    drivers: list[str]
    forecast: list[ForecastPoint]


class ServiceInfoResponse(BaseModel):
    service: str
    data_source: str
    observations: int
    first_year: int
    last_year: int
    columns: list[str]
