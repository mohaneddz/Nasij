from __future__ import annotations

import json
from pathlib import Path
import sys

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report
from sklearn.model_selection import train_test_split

from app.feature_engineering import FEATURE_ORDER

BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.append(str(BACKEND_DIR))

from shared.nfn_seed_data import load_seed_batches_and_alerts

ARTIFACT_DIR = Path(__file__).resolve().parent / "artifacts"
DATA_DIR = Path(__file__).resolve().parent / "data"


def _build_dataset_from_seed(seed: int = 42, repeats_per_batch: int = 40) -> pd.DataFrame:
    rng = np.random.default_rng(seed)
    batches_df, alerts_df = load_seed_batches_and_alerts()
    if batches_df.empty:
        raise ValueError("NFN seed batches are empty.")

    alert_batches = set(alerts_df.get("batch_id", pd.Series(dtype=str)).dropna().astype(str))
    alert_rate_by_source = (
        batches_df.assign(is_alert=batches_df["batch_id"].astype(str).isin(alert_batches).astype(float))
        .groupby("source_type", dropna=False)["is_alert"]
        .mean()
        .to_dict()
    )

    rows: list[dict[str, float | int]] = []
    for _, batch in batches_df.iterrows():
        batch_id = str(batch.get("batch_id", ""))
        source_type = str(batch.get("source_type", "C1"))
        status = str(batch.get("status", "PENDING_PICKUP"))

        announced = float(batch.get("weight_raw_e1_kg") or 0.0)
        if announced <= 0:
            continue

        received_obs = float(batch.get("weight_after_handclean_kg") or np.nan)
        washed_obs = float(batch.get("weight_clean_d2_kg") or np.nan)
        humidity = float(batch.get("humidity_percent") or batch.get("humidite_sortie_percent") or np.nan)
        temp = float(batch.get("temperature_tas_celsius") or np.nan)
        yield_pct = float(batch.get("yield_percentage") or np.nan)

        base_history_risk = float(alert_rate_by_source.get(source_type, 0.15))
        is_alert_batch = batch_id in alert_batches

        for _ in range(repeats_per_batch):
            collected = announced * float(np.clip(rng.normal(0.995, 0.02), 0.75, 1.3))
            if np.isfinite(received_obs) and received_obs > 0:
                received = received_obs * float(np.clip(rng.normal(1.0, 0.03), 0.75, 1.2))
            else:
                received = collected * float(np.clip(rng.normal(0.92, 0.08), 0.45, 1.1))

            if np.isfinite(washed_obs) and washed_obs > 0:
                washed = washed_obs * float(np.clip(rng.normal(1.0, 0.04), 0.65, 1.15))
            else:
                washed = received * float(np.clip(rng.normal(0.78, 0.12), 0.35, 1.05))

            if np.isfinite(yield_pct) and yield_pct > 0:
                transformed = announced * (yield_pct / 100.0) * float(np.clip(rng.normal(1.0, 0.06), 0.7, 1.2))
            else:
                transformed = washed * float(np.clip(rng.normal(0.9, 0.1), 0.45, 1.1))

            sold_ratio = 0.92 if status == "READY_FOR_SALE" else 0.75
            sold = transformed * float(np.clip(rng.normal(sold_ratio, 0.08), 0.25, 1.15))

            has_photo = bool(batch.get("annex_metadata") is not None and rng.random() > 0.08)
            has_location_update = bool(
                pd.notna(batch.get("location_lat"))
                and pd.notna(batch.get("location_lng"))
                and rng.random() > 0.03
            )
            edit_count = int(rng.integers(0, 6 if is_alert_batch else 4))

            mismatch_collected_vs_announced = (collected - announced) / max(announced, 1e-6)
            loss_collected_to_received = (collected - received) / max(collected, 1e-6)
            loss_received_to_washed = (received - washed) / max(received, 1e-6)
            loss_washed_to_transformed = (washed - transformed) / max(washed, 1e-6)
            loss_transformed_to_sold = (transformed - sold) / max(transformed, 1e-6)
            missing_photo = 0 if has_photo else 1
            missing_location = 0 if has_location_update else 1

            humidity_risk = 0.08 if np.isfinite(humidity) and humidity > 12.5 else 0.0
            temp_risk = 0.08 if np.isfinite(temp) and temp >= 42 else 0.0
            actor_history_risk = float(
                np.clip(
                    rng.normal(base_history_risk + humidity_risk + temp_risk, 0.09),
                    0.0,
                    1.0,
                )
            )

            risk_signal = (
                1.6 * (loss_collected_to_received > 0.25)
                + 1.2 * (loss_received_to_washed > 0.3)
                + 0.9 * (loss_washed_to_transformed > 0.25)
                + 0.7 * (edit_count >= 3)
                + 0.4 * missing_photo
                + 0.35 * missing_location
                + 0.8 * actor_history_risk
            )
            label = int(is_alert_batch or risk_signal > 1.95)

            rows.append(
                {
                    "mismatch_collected_vs_announced": mismatch_collected_vs_announced,
                    "loss_collected_to_received": loss_collected_to_received,
                    "loss_received_to_washed": loss_received_to_washed,
                    "loss_washed_to_transformed": loss_washed_to_transformed,
                    "loss_transformed_to_sold": loss_transformed_to_sold,
                    "edit_count": edit_count,
                    "missing_photo": missing_photo,
                    "missing_location": missing_location,
                    "actor_history_risk": actor_history_risk,
                    "label": label,
                }
            )

    df = pd.DataFrame(rows)
    if df.empty or df["label"].nunique() < 2:
        raise ValueError("Could not build a trainable traceability dataset from seed records.")
    return df


def _build_synthetic_fallback(n_samples: int = 3000, seed: int = 42) -> pd.DataFrame:
    rng = np.random.default_rng(seed)
    df = pd.DataFrame(
        {
            "mismatch_collected_vs_announced": rng.normal(0.08, 0.2, n_samples),
            "loss_collected_to_received": np.clip(rng.normal(0.11, 0.13, n_samples), -0.2, 0.9),
            "loss_received_to_washed": np.clip(rng.normal(0.1, 0.1, n_samples), -0.1, 0.9),
            "loss_washed_to_transformed": np.clip(rng.normal(0.08, 0.09, n_samples), -0.1, 0.9),
            "loss_transformed_to_sold": np.clip(rng.normal(0.06, 0.08, n_samples), -0.1, 0.9),
            "edit_count": rng.integers(0, 7, n_samples),
            "missing_photo": rng.integers(0, 2, n_samples),
            "missing_location": rng.integers(0, 2, n_samples),
            "actor_history_risk": rng.random(n_samples),
        }
    )

    risk_signal = (
        1.5 * (df["loss_collected_to_received"] > 0.25).astype(float)
        + 1.2 * (df["loss_received_to_washed"] > 0.3).astype(float)
        + 0.7 * (df["edit_count"] >= 3).astype(float)
        + 0.5 * df["missing_photo"]
        + 0.5 * df["missing_location"]
        + 0.8 * df["actor_history_risk"]
    )
    df["label"] = (risk_signal + rng.normal(0, 0.2, n_samples) > 1.6).astype(int)
    return df


def main() -> None:
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    try:
        data = _build_dataset_from_seed()
        data.to_csv(DATA_DIR / "traceability_training_from_seed.csv", index=False)
    except Exception as exc:
        print(f"[traceability] Seed-data training failed ({exc}); using synthetic fallback.")
        data = _build_synthetic_fallback()
        data.to_csv(DATA_DIR / "synthetic_traceability_training.csv", index=False)

    x_train, x_test, y_train, y_test = train_test_split(
        data[FEATURE_ORDER], data["label"], test_size=0.2, random_state=42, stratify=data["label"]
    )
    model = RandomForestClassifier(n_estimators=300, random_state=42, class_weight="balanced")
    model.fit(x_train, y_train)

    preds = model.predict(x_test)
    report = classification_report(y_test, preds, output_dict=False)

    joblib.dump(model, ARTIFACT_DIR / "risk_model.joblib")
    (ARTIFACT_DIR / "training_report.txt").write_text(report, encoding="utf-8")
    (ARTIFACT_DIR / "feature_order.json").write_text(
        json.dumps(FEATURE_ORDER, indent=2), encoding="utf-8"
    )
    print("Saved artifacts to", ARTIFACT_DIR)


if __name__ == "__main__":
    main()
