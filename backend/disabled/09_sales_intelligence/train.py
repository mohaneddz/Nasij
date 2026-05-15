from __future__ import annotations

import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.impute import SimpleImputer
from sklearn.metrics import mean_absolute_error, mean_absolute_percentage_error, r2_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline

BASE_DIR = Path(__file__).resolve().parent
ARTIFACT_DIR = BASE_DIR / "artifacts"
DATA_DIR = BASE_DIR / "data"

FEATURE_ORDER = [
    "table35_wool_imports_1000lb",
    "table35_wool_exports_1000lb",
    "table29_raw_wool_imports_1000lb",
    "table28_total_supply_clean_lb_m",
    "table28_mill_use_clean_lb_m",
    "table33_greasy_basis_cents_per_lb",
]
TARGET_COLUMN = "next_year_wool_exports_1000lb"


def _load_annual_metrics() -> pd.DataFrame:
    annual_path = DATA_DIR / "wool_dataset" / "eda" / "wool" / "annual_wool_metrics.csv"
    if not annual_path.exists():
        raise FileNotFoundError(
            f"Missing {annual_path}. Generate it by running data/wool_dataset/wool_eda.py first."
        )

    df = pd.read_csv(annual_path)
    for col in ["year", *FEATURE_ORDER, "table35_wool_exports_1000lb"]:
        if col not in df.columns:
            raise KeyError(f"Required column '{col}' is missing from annual metrics.")
    return df


def _build_training_frame(df: pd.DataFrame) -> pd.DataFrame:
    frame = df[["year", *FEATURE_ORDER]].copy()
    frame[TARGET_COLUMN] = df["table35_wool_exports_1000lb"].shift(-1).to_numpy()
    frame = frame.dropna(subset=[TARGET_COLUMN])
    frame = frame[frame[FEATURE_ORDER].notna().any(axis=1)].copy()
    frame = frame.sort_values("year").reset_index(drop=True)
    if len(frame) < 12:
        raise ValueError(
            "Not enough rows to train the sales model. Need at least 12 annual records after filtering."
        )
    return frame


def main() -> None:
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    raw_df = _load_annual_metrics()
    train_df = _build_training_frame(raw_df)

    x = train_df[FEATURE_ORDER]
    y = train_df[TARGET_COLUMN]
    years = train_df["year"]

    x_train, x_test, y_train, y_test, years_train, years_test = train_test_split(
        x,
        y,
        years,
        test_size=0.25,
        random_state=42,
        shuffle=True,
    )

    pipeline = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="median")),
            (
                "regressor",
                RandomForestRegressor(
                    n_estimators=450,
                    random_state=42,
                    min_samples_leaf=2,
                    max_depth=10,
                ),
            ),
        ]
    )
    pipeline.fit(x_train, y_train)

    preds = pipeline.predict(x_test)
    metrics = {
        "mae": float(mean_absolute_error(y_test, preds)),
        "mape": float(mean_absolute_percentage_error(y_test, preds)),
        "r2": float(r2_score(y_test, preds)),
        "train_rows": int(len(x_train)),
        "test_rows": int(len(x_test)),
    }

    bundle = {
        "model": pipeline,
        "feature_order": FEATURE_ORDER,
        "target": TARGET_COLUMN,
    }
    joblib.dump(bundle, ARTIFACT_DIR / "sales_model.joblib")

    metadata = {
        "feature_order": FEATURE_ORDER,
        "target": TARGET_COLUMN,
        "metrics": metrics,
        "available_years": sorted(int(v) for v in years.tolist()),
        "historical_features": [
            {
                "year": int(row["year"]),
                **{
                    feature: (
                        None if pd.isna(row[feature]) else float(row[feature])
                    )
                    for feature in FEATURE_ORDER
                },
            }
            for _, row in train_df.iterrows()
        ],
        "test_years": sorted(int(v) for v in years_test.tolist()),
        "train_years": sorted(int(v) for v in years_train.tolist()),
    }
    (ARTIFACT_DIR / "sales_metadata.json").write_text(
        json.dumps(metadata, indent=2), encoding="utf-8"
    )

    train_df.to_json(DATA_DIR / "sales_training_frame.json", orient="records", indent=2)
    print("Saved sales model artifacts to", ARTIFACT_DIR)
    print("Metrics:", json.dumps(metrics, indent=2))


if __name__ == "__main__":
    main()
