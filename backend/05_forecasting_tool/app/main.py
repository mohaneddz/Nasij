from __future__ import annotations

from fastapi import FastAPI, HTTPException

from app.data_sources import load_time_series_frame
from app.inference import run_time_series_forecast
from app.schemas import ForecastPayload, ForecastResponse, ServiceInfoResponse

app = FastAPI(title="Forecasting Tool Service", version="1.0.0")
series_df = load_time_series_frame()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/service-info", response_model=ServiceInfoResponse)
def service_info() -> ServiceInfoResponse:
    return ServiceInfoResponse(
        service="05_forecasting_tool",
        data_source="Synthetic Algerian demand built from Table 28 USA imports/exports with Eid shock",
        observations=int(len(series_df)),
        first_year=int(series_df["year"].iloc[0]),
        last_year=int(series_df["year"].iloc[-1]),
        columns=list(series_df.columns),
    )


@app.get("/year/{year}")
def year_data(year: int) -> dict:
    row = series_df.loc[series_df["year"] == year]
    if row.empty:
        raise HTTPException(status_code=404, detail=f"Year {year} not found in historical series.")
    rec = row.iloc[0].to_dict()
    rec["year"] = int(rec["year"])
    return rec


@app.post("/forecast", response_model=ForecastResponse)
def forecast(payload: ForecastPayload) -> ForecastResponse:
    try:
        output = run_time_series_forecast(series_df, payload)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return ForecastResponse(**output)


@app.post("/forecast-next-year")
def forecast_next_year() -> dict:
    output = run_time_series_forecast(series_df, ForecastPayload(horizon_years=1))
    return output["forecast"][0]
