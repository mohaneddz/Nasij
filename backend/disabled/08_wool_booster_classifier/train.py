from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import joblib
import numpy as np
from PIL import Image
from sklearn.ensemble import GradientBoostingClassifier, HistGradientBoostingClassifier
from sklearn.metrics import accuracy_score, classification_report, f1_score
from sklearn.model_selection import train_test_split

from app.features import FEATURE_ORDER, extract_features_from_bytes

BASE_DIR = Path(__file__).resolve().parent
ARTIFACT_DIR = BASE_DIR / "artifacts"
DATA_DIR = BASE_DIR / "data"
PROCESSED_DIR = DATA_DIR / "processed"
SOURCE_DIR = BASE_DIR.parent / "07_wool_on_skin_classifier" / "wool"
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".bmp", ".webp"}
CLASS_NAMES = ["new", "slightly", "moderate", "bad", "unusable"]


def _reset_processed_dir() -> None:
    if PROCESSED_DIR.exists():
        for file_path in PROCESSED_DIR.rglob("*"):
            if file_path.is_file():
                file_path.unlink()
    for class_name in CLASS_NAMES:
        (PROCESSED_DIR / class_name).mkdir(parents=True, exist_ok=True)


def _infer_label_from_name(stem: str) -> str:
    lower = stem.lower()
    if "unusable" in lower:
        return "unusable"
    if "slightly" in lower:
        return "slightly"
    if "moderate" in lower:
        return "moderate"
    if "bad" in lower:
        return "bad"
    if "new" in lower:
        return "new"
    return ""


def _trim_white_and_zoom_in(image: Image.Image, zoom_ratio: float = 0.96) -> Image.Image:
    rgb = image.convert("RGB")
    arr = np.asarray(rgb)

    non_white = np.any(arr < 245, axis=2)
    if np.any(non_white):
        ys, xs = np.where(non_white)
        top, bottom = int(ys.min()), int(ys.max()) + 1
        left, right = int(xs.min()), int(xs.max()) + 1
        rgb = rgb.crop((left, top, right, bottom))

    width, height = rgb.size
    crop_w = max(1, int(width * zoom_ratio))
    crop_h = max(1, int(height * zoom_ratio))
    left = max(0, (width - crop_w) // 2)
    top = max(0, (height - crop_h) // 2)
    return rgb.crop((left, top, left + crop_w, top + crop_h))


def _save_5x5_tiles(image: Image.Image, output_dir: Path, stem: str) -> int:
    width, height = image.size
    xs = np.linspace(0, width, 6, dtype=int)
    ys = np.linspace(0, height, 6, dtype=int)

    count = 0
    for row in range(5):
        for col in range(5):
            left, right = int(xs[col]), int(xs[col + 1])
            top, bottom = int(ys[row]), int(ys[row + 1])
            tile = image.crop((left, top, right, bottom))
            tile.save(output_dir / f"{stem}_r{row + 1}_c{col + 1}.png")
            count += 1
    return count


def preprocess_source_images() -> dict[str, int]:
    if not SOURCE_DIR.exists():
        raise FileNotFoundError(f"Wool source folder not found: {SOURCE_DIR}")

    _reset_processed_dir()
    summary = {class_name: 0 for class_name in CLASS_NAMES}
    summary["source_images"] = 0
    summary["skipped_images"] = 0

    for image_path in sorted(SOURCE_DIR.iterdir()):
        if not image_path.is_file() or image_path.suffix.lower() not in IMAGE_EXTENSIONS:
            continue

        label = _infer_label_from_name(image_path.stem)
        if not label:
            summary["skipped_images"] += 1
            continue

        with Image.open(image_path) as image:
            cropped = _trim_white_and_zoom_in(image, zoom_ratio=0.96)
            tile_count = _save_5x5_tiles(cropped, PROCESSED_DIR / label, image_path.stem)

        summary[label] += tile_count
        summary["source_images"] += 1

    return summary


def _build_dataset() -> tuple[np.ndarray, np.ndarray]:
    x_rows: list[np.ndarray] = []
    y_rows: list[int] = []
    class_to_idx = {name: idx for idx, name in enumerate(CLASS_NAMES)}

    for class_name in CLASS_NAMES:
        folder = PROCESSED_DIR / class_name
        for img_path in sorted(folder.glob("*.png")):
            features = extract_features_from_bytes(img_path.read_bytes())
            x_rows.append(features)
            y_rows.append(class_to_idx[class_name])

    if len(x_rows) < 50:
        raise ValueError("Not enough processed tile samples to train.")

    x = np.vstack(x_rows).astype(np.float32)
    y = np.array(y_rows, dtype=np.int32)
    return x, y


def _maybe_build_xgboost(num_classes: int) -> tuple[str, Any] | None:
    try:
        from xgboost import XGBClassifier
    except Exception:
        return None

    model = XGBClassifier(
        objective="multi:softprob",
        eval_metric="mlogloss",
        num_class=num_classes,
        n_estimators=350,
        max_depth=6,
        learning_rate=0.05,
        subsample=0.9,
        colsample_bytree=0.9,
        reg_lambda=1.0,
        random_state=42,
        n_jobs=-1,
    )
    return ("xgboost", model)


def _maybe_build_lightgbm(num_classes: int) -> tuple[str, Any] | None:
    try:
        from lightgbm import LGBMClassifier
    except Exception:
        return None

    model = LGBMClassifier(
        objective="multiclass",
        n_estimators=500,
        learning_rate=0.05,
        num_leaves=31,
        subsample=0.9,
        colsample_bytree=0.9,
        random_state=42,
        n_jobs=-1,
        class_weight="balanced",
    )
    return ("lightgbm", model)


def _build_candidates(num_classes: int) -> list[tuple[str, Any]]:
    candidates: list[tuple[str, Any]] = []

    xgb_candidate = _maybe_build_xgboost(num_classes)
    if xgb_candidate is not None:
        candidates.append(xgb_candidate)

    lgbm_candidate = _maybe_build_lightgbm(num_classes)
    if lgbm_candidate is not None:
        candidates.append(lgbm_candidate)

    candidates.append(
        (
            "hist_gradient_boosting",
            HistGradientBoostingClassifier(
                max_depth=8,
                learning_rate=0.07,
                max_iter=420,
                random_state=42,
            ),
        )
    )
    candidates.append(
        (
            "gradient_boosting",
            GradientBoostingClassifier(
                n_estimators=300,
                learning_rate=0.05,
                max_depth=3,
                random_state=42,
            ),
        )
    )
    return candidates


def train_model() -> dict[str, Any]:
    x, y = _build_dataset()
    x_train, x_test, y_train, y_test = train_test_split(
        x, y, test_size=0.2, random_state=42, stratify=y
    )

    candidates = _build_candidates(num_classes=len(CLASS_NAMES))
    if not candidates:
        raise RuntimeError("No candidate models available. Install xgboost/lightgbm or use sklearn boosters.")

    candidate_metrics: dict[str, dict[str, float]] = {}
    best_name = ""
    best_model: Any = None
    best_macro_f1 = -1.0
    best_accuracy = -1.0

    for name, model in candidates:
        model.fit(x_train, y_train)
        pred = model.predict(x_test)
        macro_f1 = float(f1_score(y_test, pred, average="macro"))
        acc = float(accuracy_score(y_test, pred))
        candidate_metrics[name] = {"macro_f1": macro_f1, "accuracy": acc}

        if (macro_f1 > best_macro_f1) or (macro_f1 == best_macro_f1 and acc > best_accuracy):
            best_macro_f1 = macro_f1
            best_accuracy = acc
            best_name = name
            best_model = model

    if best_model is None:
        raise RuntimeError("Could not select a best model.")

    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    joblib.dump(best_model, ARTIFACT_DIR / "best_model.joblib")

    report = classification_report(
        y_test,
        best_model.predict(x_test),
        target_names=CLASS_NAMES,
        output_dict=True,
        zero_division=0,
    )

    model_config = {
        "best_model_name": best_name,
        "selection_metric": "macro_f1",
        "classes": CLASS_NAMES,
        "feature_version": "wool_booster_features_v1",
        "feature_order": FEATURE_ORDER,
        "candidates": candidate_metrics,
    }
    (ARTIFACT_DIR / "model_config.json").write_text(
        json.dumps(model_config, indent=2), encoding="utf-8"
    )

    training_report = {
        "metrics": {
            "best_model_name": best_name,
            "best_macro_f1": best_macro_f1,
            "best_accuracy": best_accuracy,
            "train_rows": int(len(x_train)),
            "test_rows": int(len(x_test)),
            "num_classes": len(CLASS_NAMES),
        },
        "candidates": candidate_metrics,
        "classification_report": report,
    }
    (ARTIFACT_DIR / "training_report.json").write_text(
        json.dumps(training_report, indent=2), encoding="utf-8"
    )

    return training_report


def main() -> None:
    np.random.seed(42)
    prep_summary = preprocess_source_images()
    training_report = train_model()

    manifest = {
        "source_dir": str(SOURCE_DIR),
        "processed_dir": str(PROCESSED_DIR),
        "classes": CLASS_NAMES,
        "tiles": prep_summary,
    }
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    (DATA_DIR / "dataset_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    print("Prepared wool tiles:", json.dumps(prep_summary, indent=2))
    print(
        "Best model:",
        training_report["metrics"]["best_model_name"],
        "macro_f1=",
        round(float(training_report["metrics"]["best_macro_f1"]), 4),
    )


if __name__ == "__main__":
    main()
