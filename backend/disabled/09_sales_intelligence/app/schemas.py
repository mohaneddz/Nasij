from __future__ import annotations

from pydantic import BaseModel, Field


class SalesForecastPayload(BaseModel):
    year: int | None = Field(default=None, description="Historical year to preload as baseline features.")
    table35_wool_imports_1000lb: float | None = None
    table35_wool_exports_1000lb: float | None = None
    table29_raw_wool_imports_1000lb: float | None = None
    table28_total_supply_clean_lb_m: float | None = None
    table28_mill_use_clean_lb_m: float | None = None
    table33_greasy_basis_cents_per_lb: float | None = None


class SalesForecastResponse(BaseModel):
    year_used: int | None
    input_source: str
    predicted_next_year_wool_exports_1000lb: float
    missing_features_imputed: list[str]


class ServiceInfoResponse(BaseModel):
    model_target: str
    features: list[str]
    metrics: dict[str, float | int]
    available_years: list[int]


class YearDataResponse(BaseModel):
    year: int
    features: dict[str, float | None]
