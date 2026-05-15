from __future__ import annotations

from pathlib import Path
import sys

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report
from sklearn.model_selection import train_test_split

from app.catalog import load_catalog
from app.geo_utils import haversine_km

BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.append(str(BACKEND_DIR))

from shared.nfn_seed_data import load_seed_batches_and_alerts

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
ARTIFACT_DIR = BASE_DIR / "artifacts"


def _quality_from_batch(batch: pd.Series) -> str:
    classification = str(batch.get("classification") or "")
    contamination = float(batch.get("taux_matiere_vegetale_percent") or 3.5)
    if classification == "CLASSE_A_PROPRE" and contamination <= 3.0:
        return "high"
    if contamination >= 5.2:
        return "low"
    return "medium"


def _actor_type_from_status(status: str) -> str:
    return "collector" if status in {"PENDING_PICKUP", "COLLECTED_BY_BUYER"} else "depot"


def build_training_data(repeats_per_batch: int = 30, seed: int = 42) -> pd.DataFrame:
    rng = np.random.default_rng(seed)
    catalog = load_catalog()
    batches_df, _ = load_seed_batches_and_alerts()
    if batches_df.empty:
        raise ValueError("NFN seed batches are empty.")

    rows: list[dict[str, float | int]] = []

    for _, batch in batches_df.iterrows():
        base_lat = float(batch.get("location_lat") or np.nan)
        base_lon = float(batch.get("location_lng") or np.nan)
        if not np.isfinite(base_lat) or not np.isfinite(base_lon):
            continue

        quantity = float(batch.get("weight_raw_e1_kg") or 0.0)
        if quantity <= 0:
            quantity = 120.0

        required_quality = _quality_from_batch(batch)
        actor_type = _actor_type_from_status(str(batch.get("status", "PENDING_PICKUP")))
        subset = catalog[catalog["actor_type"] == actor_type].copy()
        if subset.empty:
            continue

        for _ in range(repeats_per_batch):
            req_lat = float(base_lat + rng.normal(0, 0.17))
            req_lon = float(base_lon + rng.normal(0, 0.17))
            req_qty = float(max(20.0, quantity * np.clip(rng.normal(1.0, 0.08), 0.55, 1.7)))

            candidate_rows: list[dict[str, float | int | str]] = []
            for _, actor in subset.iterrows():
                q_match = (
                    1.0
                    if required_quality == actor["speciality"]
                    else (0.7 if "medium" in [required_quality, actor["speciality"]] else 0.4)
                )
                dist = float(haversine_km(req_lat, req_lon, actor["lat"], actor["lon"]))
                capacity_ratio = float(min(1.0, actor["capacity_kg"] / max(req_qty, 1.0)))
                desirability = (
                    1.6 * (1.0 / (1.0 + dist / 35.0))
                    + 1.0 * float(actor["reliability"])
                    + 0.85 * float(actor["rating"])
                    + 0.9 * capacity_ratio
                    + 0.7 * q_match
                )
                candidate_rows.append(
                    {
                        "actor_id": str(actor["actor_id"]),
                        "distance_km": dist,
                        "reliability": float(actor["reliability"]),
                        "rating": float(actor["rating"]),
                        "capacity_ratio": capacity_ratio,
                        "quality_match": float(q_match),
                        "desirability": desirability,
                    }
                )

            scored = pd.DataFrame(candidate_rows).sort_values("desirability", ascending=False)
            winner_actor = str(scored.iloc[0]["actor_id"])

            for row in candidate_rows:
                rows.append(
                    {
                        "distance_km": row["distance_km"],
                        "reliability": row["reliability"],
                        "rating": row["rating"],
                        "capacity_ratio": row["capacity_ratio"],
                        "quality_match": row["quality_match"],
                        "label": int(row["actor_id"] == winner_actor),
                    }
                )

    return pd.DataFrame(rows)


def main() -> None:
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    try:
        df = build_training_data()
        if df.empty or df["label"].nunique() < 2:
            raise ValueError("No trainable rows.")
        df.to_csv(DATA_DIR / "matching_training_data.csv", index=False)
    except Exception as exc:
        print(f"[matching] Seed-data training failed ({exc}); using synthetic fallback.")
        df = pd.DataFrame(
            {
                "distance_km": np.random.uniform(1, 180, 2400),
                "reliability": np.random.uniform(0.6, 0.95, 2400),
                "rating": np.random.uniform(0.65, 0.98, 2400),
                "capacity_ratio": np.random.uniform(0.2, 1.0, 2400),
                "quality_match": np.random.choice([0.4, 0.7, 1.0], 2400, p=[0.25, 0.45, 0.3]),
            }
        )
        base_score = (
            1.5 * (1 / (1 + df["distance_km"] / 35.0))
            + 0.9 * df["reliability"]
            + 0.8 * df["rating"]
            + 0.85 * df["capacity_ratio"]
            + 0.65 * df["quality_match"]
        )
        df["label"] = (base_score > base_score.median()).astype(int)
        df.to_csv(DATA_DIR / "matching_training_data_fallback.csv", index=False)

    features = ["distance_km", "reliability", "rating", "capacity_ratio", "quality_match"]
    x_train, x_test, y_train, y_test = train_test_split(
        df[features], df["label"], test_size=0.2, random_state=42, stratify=df["label"]
    )

    model = RandomForestClassifier(n_estimators=260, random_state=42, class_weight="balanced")
    model.fit(x_train, y_train)
    preds = model.predict(x_test)
    report = classification_report(y_test, preds)

    joblib.dump(model, ARTIFACT_DIR / "matching_model.joblib")
    (ARTIFACT_DIR / "training_report.txt").write_text(report, encoding="utf-8")
    print("Saved artifacts to", ARTIFACT_DIR)


if __name__ == "__main__":
    main()
