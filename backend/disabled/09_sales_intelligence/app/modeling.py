from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import joblib
import numpy as np
import pandas as pd

ARTIFACT_DIR = Path(__file__).resolve().parents[1] / "artifacts"
MODEL_PATH = ARTIFACT_DIR / "sales_model.joblib"
METADATA_PATH = ARTIFACT_DIR / "sales_metadata.json"


class SalesModelBundle:
    def __init__(self) -> None:
        if not MODEL_PATH.exists() or not METADATA_PATH.exists():
            raise FileNotFoundError(
                f"Missing service artifacts in {ARTIFACT_DIR}. Run train.py first."
            )

        bundle = joblib.load(MODEL_PATH)
        self.model = bundle["model"]
        self.feature_order: list[str] = list(bundle["feature_order"])
        self.target = str(bundle["target"])

        metadata = json.loads(METADATA_PATH.read_text(encoding="utf-8"))
        self.metrics: dict[str, Any] = dict(metadata.get("metrics", {}))
        self.available_years: list[int] = [int(v) for v in metadata.get("available_years", [])]

        raw_rows = metadata.get("historical_features", [])
        self.historical_features_by_year: dict[int, dict[str, float | None]] = {}
        for row in raw_rows:
            year = int(row["year"])
            self.historical_features_by_year[year] = {
                feature: (
                    None if row.get(feature) is None else float(row.get(feature))
                )
                for feature in self.feature_order
            }

    def predict(self, x: np.ndarray) -> float:
        frame = pd.DataFrame([x], columns=self.feature_order)
        return float(self.model.predict(frame)[0])
