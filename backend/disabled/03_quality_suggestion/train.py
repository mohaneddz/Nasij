from __future__ import annotations

from pathlib import Path
import sys

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report
from sklearn.model_selection import train_test_split

from app.features import FEATURE_ORDER

BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.append(str(BACKEND_DIR))

from shared.nfn_seed_data import load_seed_batches_and_alerts

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
ARTIFACT_DIR = BASE_DIR / "artifacts"
LABELS = ["low", "medium", "high"]


def _build_dataset_from_seed(seed: int = 42, repeats_per_batch: int = 18) -> pd.DataFrame:
    rng = np.random.default_rng(seed)
    batches_df, alerts_df = load_seed_batches_and_alerts()
    if batches_df.empty:
        raise ValueError("NFN seed batches are empty.")

    alert_batches = set(alerts_df.get("batch_id", pd.Series(dtype=str)).dropna().astype(str))
    source_alert_rate = (
        batches_df.assign(is_alert=batches_df["batch_id"].astype(str).isin(alert_batches).astype(float))
        .groupby("source_type", dropna=False)["is_alert"]
        .mean()
        .to_dict()
    )

    state_map = {
        "PENDING_PICKUP": 0.0,
        "COLLECTED_BY_BUYER": 0.0,
        "AT_D1_STOCKAGE": 1.0,
        "AT_D2_LAVAGE": 1.0,
        "IN_TRANSFORMATION": 2.0,
        "READY_FOR_SALE": 2.0,
    }

    rows: list[dict[str, float | int]] = []
    for _, batch in batches_df.iterrows():
        batch_id = str(batch.get("batch_id", ""))
        source_type = str(batch.get("source_type", "C1"))
        status = str(batch.get("status", "PENDING_PICKUP"))
        classification = str(batch.get("classification") or "")

        clean_base = float(batch.get("proprete_score") or 3) / 5.0
        contamination_base = float(batch.get("taux_matiere_vegetale_percent") or 3.5) / 10.0
        humidity = float(batch.get("humidity_percent") or batch.get("humidite_sortie_percent") or 11.5)
        moisture_warning_base = humidity > 12.5
        photo_conf_base = 0.9 if str(batch.get("annex_metadata")) != "{}" else 0.7
        reliability_base = float(1.0 - source_alert_rate.get(source_type, 0.2))
        declared_state_code = float(state_map.get(status, 3.0))
        is_alert_batch = batch_id in alert_batches

        for _ in range(repeats_per_batch):
            cleanliness_score = float(np.clip(rng.normal(clean_base, 0.07), 0.0, 1.0))
            contamination_score = float(np.clip(rng.normal(contamination_base, 0.08), 0.0, 1.0))
            moisture_warning = int(
                moisture_warning_base or rng.random() < (0.35 if contamination_score > 0.5 else 0.1)
            )
            photo_confidence = float(np.clip(rng.normal(photo_conf_base, 0.08), 0.25, 1.0))
            actor_reliability = float(np.clip(rng.normal(reliability_base, 0.08), 0.15, 1.0))

            quality_score = (
                1.35 * cleanliness_score
                - 1.15 * contamination_score
                - 0.55 * moisture_warning
                + 0.35 * photo_confidence
                + 0.35 * actor_reliability
            )

            if classification == "CLASSE_A_PROPRE":
                quality_score += 0.25
            elif classification == "CLASSE_B_SOUILLEE":
                quality_score -= 0.2
            if is_alert_batch:
                quality_score -= 0.22

            if quality_score < 0.18:
                label = 0
            elif quality_score < 0.76:
                label = 1
            else:
                label = 2

            rows.append(
                {
                    "cleanliness_score": cleanliness_score,
                    "contamination_score": contamination_score,
                    "moisture_warning": float(moisture_warning),
                    "photo_confidence": photo_confidence,
                    "actor_reliability": actor_reliability,
                    "declared_state_code": declared_state_code,
                    "label": int(label),
                }
            )

    df = pd.DataFrame(rows)
    if df.empty or df["label"].nunique() < 2:
        raise ValueError("Could not build a trainable quality dataset from seed records.")
    return df


def _build_synthetic_fallback(n_samples: int = 2500, seed: int = 42) -> pd.DataFrame:
    rng = np.random.default_rng(seed)
    df = pd.DataFrame(
        {
            "cleanliness_score": rng.uniform(0, 1, n_samples),
            "contamination_score": rng.uniform(0, 1, n_samples),
            "moisture_warning": rng.integers(0, 2, n_samples).astype(float),
            "photo_confidence": rng.uniform(0.3, 1.0, n_samples),
            "actor_reliability": rng.uniform(0.2, 1.0, n_samples),
            "declared_state_code": rng.integers(0, 4, n_samples).astype(float),
        }
    )

    quality_score = (
        1.3 * df["cleanliness_score"]
        - 1.2 * df["contamination_score"]
        - 0.5 * df["moisture_warning"]
        + 0.4 * df["photo_confidence"]
        + 0.2 * df["actor_reliability"]
    )
    bins = [-10, 0.15, 0.7, 10]
    df["label"] = pd.cut(quality_score, bins=bins, labels=[0, 1, 2]).astype(int)
    return df


def main() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)

    try:
        df = _build_dataset_from_seed()
        df.to_csv(DATA_DIR / "quality_training_from_seed.csv", index=False)
    except Exception as exc:
        print(f"[quality] Seed-data training failed ({exc}); using synthetic fallback.")
        df = _build_synthetic_fallback()
        df.to_csv(DATA_DIR / "synthetic_quality_training.csv", index=False)

    x_train, x_test, y_train, y_test = train_test_split(
        df[FEATURE_ORDER], df["label"], test_size=0.2, random_state=42, stratify=df["label"]
    )
    model = RandomForestClassifier(n_estimators=320, random_state=42, class_weight="balanced")
    model.fit(x_train, y_train)
    preds = model.predict(x_test)
    report = classification_report(y_test, preds, target_names=LABELS)

    joblib.dump(model, ARTIFACT_DIR / "quality_model.joblib")
    (ARTIFACT_DIR / "training_report.txt").write_text(report, encoding="utf-8")
    print("Saved artifacts to", ARTIFACT_DIR)


if __name__ == "__main__":
    main()
