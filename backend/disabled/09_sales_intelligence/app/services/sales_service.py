from __future__ import annotations

import numpy as np

from app.modeling import SalesModelBundle
from app.schemas import SalesForecastPayload


def _payload_to_overrides(payload: SalesForecastPayload) -> dict[str, float]:
    out: dict[str, float] = {}
    values = payload.model_dump(exclude_none=True)
    values.pop("year", None)
    for key, value in values.items():
        out[key] = float(value)
    return out


def _resolve_feature_row(
    bundle: SalesModelBundle,
    year: int | None,
    overrides: dict[str, float],
) -> tuple[dict[str, float | None], int | None, str]:
    if year is not None:
        if year not in bundle.historical_features_by_year:
            raise ValueError(
                f"Year {year} is not available. Choose one of: {bundle.available_years}."
            )
        row = dict(bundle.historical_features_by_year[year])
        source = "historical_year_with_overrides" if overrides else "historical_year"
    else:
        row = {feature: None for feature in bundle.feature_order}
        source = "manual_features"

    row.update(overrides)
    return row, year, source


def get_year_snapshot(bundle: SalesModelBundle, year: int) -> dict[str, float | None]:
    if year not in bundle.historical_features_by_year:
        raise ValueError(
            f"Year {year} is not available. Choose one of: {bundle.available_years}."
        )
    return dict(bundle.historical_features_by_year[year])


def forecast_next_year_exports(
    bundle: SalesModelBundle,
    payload: SalesForecastPayload,
) -> dict[str, object]:
    overrides = _payload_to_overrides(payload)
    feature_row, year_used, source = _resolve_feature_row(bundle, payload.year, overrides)

    vector = np.array([feature_row.get(name) for name in bundle.feature_order], dtype=float)
    if np.isnan(vector).all():
        raise ValueError(
            "No usable features were provided. Supply `year` or at least one explicit feature value."
        )

    missing = [
        name for name, value in zip(bundle.feature_order, vector.tolist(), strict=False) if np.isnan(value)
    ]

    prediction = bundle.predict(vector)
    return {
        "year_used": year_used,
        "input_source": source,
        "predicted_next_year_wool_exports_1000lb": round(prediction, 3),
        "missing_features_imputed": missing,
    }
