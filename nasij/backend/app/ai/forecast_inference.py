from __future__ import annotations

import numpy as np
import pandas as pd

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


def _linear_forecast(series: np.ndarray, horizon_years: int, lookback_years: int) -> tuple[list[float], float]:
    if series.size < 3:
        raise ValueError("Need at least 3 historical observations for forecasting.")

    window = min(lookback_years, int(series.size))
    y = series[-window:]
    x = np.arange(window, dtype=float)
    slope, intercept = np.polyfit(x, y, 1)

    fitted = slope * x + intercept
    residual = y - fitted
    std = float(np.std(residual))
    avg = max(1.0, float(np.mean(np.abs(y))))
    confidence = max(0.45, min(0.95, 1.0 - (std / avg)))

    future_x = np.arange(window, window + horizon_years, dtype=float)
    preds = slope * future_x + intercept
    preds = [round(float(max(0.0, p)), 3) for p in preds]
    return preds, round(confidence, 4)


def run_time_series_forecast(frame: pd.DataFrame, payload: ForecastPayload) -> dict:
    years = frame["year"].to_numpy(dtype=int)
    demand = frame["demand_kg"].to_numpy(dtype=float)

    demand_forecast, confidence = _linear_forecast(demand, payload.horizon_years, payload.lookback_years)

    last_year = int(years[-1])
    forecast_rows = []
    for i in range(payload.horizon_years):
        forecast_rows.append(
            {
                "year": last_year + i + 1,
                "demand_kg": demand_forecast[i],
            }
        )

    return {
        "forecast_type": "synthetic_algerian_wool_demand",
        "horizon_years": payload.horizon_years,
        "lookback_years": payload.lookback_years,
        "last_historical_year": last_year,
        "confidence": confidence,
        "drivers": [
            "USA imports baseline (downscaled for Algeria)",
            "USA exports adjustment",
            "Eid al-Adha shock pattern",
            "linear time-series extrapolation",
        ],
        "forecast": forecast_rows,
    }
