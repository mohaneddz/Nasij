from __future__ import annotations

from pathlib import Path
import sys

import joblib
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline

BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.append(str(BACKEND_DIR))

from shared.nfn_seed_data import load_seed_batches_and_alerts

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
ARTIFACT_DIR = BASE_DIR / "artifacts"


def build_dataset() -> pd.DataFrame:
    batches_df, alerts_df = load_seed_batches_and_alerts()
    records: list[tuple[str, str]] = []

    for _, row in batches_df.iterrows():
        wilaya = str(row.get("wilaya") or "unknown region")
        breed = str(row.get("breed") or "mixed").replace("_", " ").lower()
        status = str(row.get("status") or "PENDING_PICKUP")
        batch_id = str(row.get("batch_id") or "NFN-000")
        weight = float(row.get("weight_raw_e1_kg") or 120.0)
        contamination = float(row.get("taux_matiere_vegetale_percent") or 3.0)
        humidity = float(row.get("humidity_percent") or row.get("humidite_sortie_percent") or 11.0)

        records.extend(
            [
                ("create_collection_request", f"I have {weight:.0f} kg of {breed} wool in {wilaya}"),
                ("create_collection_request", f"schedule pickup for batch {batch_id} tomorrow"),
                ("create_collection_request", f"need a collector for {weight:.0f} kilos at {wilaya}"),
                ("ask_route", f"best route for collector around {wilaya} today"),
                ("ask_route", f"which depot should handle batch {batch_id}"),
                ("ask_route", f"optimize truck route for wool pickup in {wilaya}"),
                ("ask_quality", f"is batch {batch_id} quality good enough for yarn"),
                ("ask_quality", f"contamination is {contamination:.1f} percent what should we do"),
                ("ask_quality", f"humidity {humidity:.1f} on this wool lot does it need drying"),
                ("ask_admin_report", f"show risk summary for {wilaya}"),
                ("ask_admin_report", f"which lots in status {status} need attention"),
            ]
        )

    for _, alert in alerts_df.iterrows():
        batch_id = str(alert.get("batch_id") or "NFN-000")
        alert_type = str(alert.get("alert_type") or "ALERT")
        description = str(alert.get("description") or "")
        records.extend(
            [
                ("ask_admin_report", f"show alerts of type {alert_type}"),
                ("ask_admin_report", f"why is batch {batch_id} flagged"),
                ("ask_admin_report", description),
                ("ask_quality", f"quality warning for {batch_id}: {description}"),
            ]
        )

    records.extend(
        [
            ("fallback", "hello"),
            ("fallback", "good morning"),
            ("fallback", "what can you do"),
            ("fallback", "thanks"),
            ("fallback", "ok"),
            ("fallback", "hi assistant"),
        ]
    )

    # Lightweight lexical augmentation to improve robustness without changing intent semantics.
    augment: list[tuple[str, str]] = []
    for intent, text in records:
        lower = text.lower()
        if "wool" in lower:
            augment.append((intent, lower.replace("wool", "fiber")))
        if "pickup" in lower:
            augment.append((intent, lower.replace("pickup", "collection")))
        if "route" in lower:
            augment.append((intent, lower.replace("route", "itinerary")))
    all_records = records + augment
    return pd.DataFrame(all_records, columns=["intent", "text"])


def main() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)

    df = build_dataset()
    df.to_csv(DATA_DIR / "assistant_intents.csv", index=False)
    x_train, x_test, y_train, y_test = train_test_split(
        df["text"], df["intent"], test_size=0.25, random_state=42, stratify=df["intent"]
    )

    model = Pipeline(
        steps=[
            ("tfidf", TfidfVectorizer(ngram_range=(1, 2), min_df=1)),
            ("clf", LogisticRegression(max_iter=600)),
        ]
    )
    model.fit(x_train, y_train)
    preds = model.predict(x_test)
    report = classification_report(y_test, preds, zero_division=0)

    joblib.dump(model, ARTIFACT_DIR / "intent_classifier.joblib")
    (ARTIFACT_DIR / "training_report.txt").write_text(report, encoding="utf-8")
    print("Saved artifacts to", ARTIFACT_DIR)


if __name__ == "__main__":
    main()
