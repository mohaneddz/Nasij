from __future__ import annotations

from fastapi import FastAPI, HTTPException

from app.modeling import SalesModelBundle
from app.schemas import (
    SalesForecastPayload,
    SalesForecastResponse,
    ServiceInfoResponse,
    YearDataResponse,
)
from app.services.sales_service import forecast_next_year_exports, get_year_snapshot

app = FastAPI(title="Sales Intelligence Service", version="0.1.0")
bundle = SalesModelBundle()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/service-info", response_model=ServiceInfoResponse)
def service_info() -> ServiceInfoResponse:
    return ServiceInfoResponse(
        model_target=bundle.target,
        features=bundle.feature_order,
        metrics=bundle.metrics,
        available_years=bundle.available_years,
    )


@app.get("/year/{year}", response_model=YearDataResponse)
def year_data(year: int) -> YearDataResponse:
    try:
        payload = get_year_snapshot(bundle, year)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return YearDataResponse(year=year, features=payload)


@app.post("/forecast-next-year", response_model=SalesForecastResponse)
def forecast_next_year(payload: SalesForecastPayload) -> SalesForecastResponse:
    try:
        output = forecast_next_year_exports(bundle, payload)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return SalesForecastResponse(**output)
