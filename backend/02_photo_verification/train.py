from __future__ import annotations

from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from PIL import Image, ImageDraw
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report
from sklearn.model_selection import train_test_split
from sklearn.datasets import fetch_openml

from app.image_features import FEATURE_ORDER, extract_features

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
ARTIFACT_DIR = BASE_DIR / "artifacts"
WOOL_DIR = Path(__file__).resolve().parents[1] / "07_wool_on_skin_classifier" / "wool"
SHEEP_DIR = Path(__file__).resolve().parents[1] / "06_sheep_breed_classifier" / "data" / "sheep_dataset"
RESAMPLE_BICUBIC = getattr(Image, "Resampling", Image).BICUBIC
IMAGE_EXTENSIONS = ("*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp")


def create_synthetic_negative_images(out_dir: Path, count: int = 220, seed: int = 42) -> list[Path]:
    out_dir.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(seed)
    paths: list[Path] = []
    for idx in range(count):
        img = Image.new("RGB", (224, 224), tuple(int(x) for x in rng.integers(0, 255, 3)))
        draw = ImageDraw.Draw(img)
        for _ in range(rng.integers(8, 25)):
            x0, y0 = int(rng.integers(0, 180)), int(rng.integers(0, 180))
            x1, y1 = x0 + int(rng.integers(20, 90)), y0 + int(rng.integers(20, 90))
            color = tuple(int(x) for x in rng.integers(0, 255, 3))
            draw.rectangle([x0, y0, x1, y1], outline=color, width=int(rng.integers(1, 4)))
        path = out_dir / f"neg_{idx:04d}.png"
        img.save(path)
        paths.append(path)
    return paths


def create_real_negative_images(out_dir: Path, count: int = 260, seed: int = 42) -> list[Path]:
    out_dir.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(seed)
    ds = fetch_openml(name="CIFAR_10_small", version=1, as_frame=False)
    x = ds.data

    available = np.arange(len(x))
    if len(available) < count:
        count = len(available)
    sampled_idx = rng.choice(available, size=count, replace=False)

    paths: list[Path] = []
    for i, idx in enumerate(sampled_idx):
        arr = x[int(idx)].reshape(3, 32, 32).transpose(1, 2, 0).astype(np.uint8)
        img = Image.fromarray(arr, mode="RGB").resize((224, 224), RESAMPLE_BICUBIC)
        path = out_dir / f"real_neg_{i:04d}.png"
        img.save(path)
        paths.append(path)
    return paths


def _collect_images(source_dir: Path) -> list[Path]:
    images: list[Path] = []
    for pattern in IMAGE_EXTENSIONS:
        images.extend(source_dir.rglob(pattern))
    return sorted({path.resolve() for path in images})


def create_real_positive_images(out_dir: Path, source_dir: Path) -> list[Path]:
    out_dir.mkdir(parents=True, exist_ok=True)
    source_images = _collect_images(source_dir)
    if not source_images:
        raise FileNotFoundError(f"No source images found in {source_dir}")

    paths: list[Path] = []
    for i, source_path in enumerate(source_images):
        with Image.open(source_path) as img:
            rgb = img.convert("RGB").resize((224, 224), RESAMPLE_BICUBIC)
            path = out_dir / f"real_wool_{i:04d}.png"
            rgb.save(path)
            paths.append(path)
    return paths


def build_dataset() -> pd.DataFrame:
    try:
        negatives = create_real_negative_images(DATA_DIR / "real_non_wool")
    except Exception as exc:
        print(f"[photo] Real negative image download failed ({exc}); using synthetic fallback negatives.")
        negatives = create_synthetic_negative_images(DATA_DIR / "generated_non_wool")
    try:
        positives = create_real_positive_images(DATA_DIR / "real_wool", WOOL_DIR)
    except Exception as exc:
        print(f"[photo] Real wool image load failed ({exc}); falling back to sheep dataset positives.")
        positives = create_real_positive_images(DATA_DIR / "real_wool", SHEEP_DIR)

    print(f"[photo] Positives={len(positives)} from {DATA_DIR / 'real_wool'}, Negatives={len(negatives)}")
    records: list[dict[str, float | int]] = []

    for path in positives:
        feats = extract_features(path.read_bytes())
        records.append({**dict(zip(FEATURE_ORDER, feats.tolist())), "label": 1})
    for path in negatives:
        feats = extract_features(path.read_bytes())
        records.append({**dict(zip(FEATURE_ORDER, feats.tolist())), "label": 0})
    return pd.DataFrame(records)


def main() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)

    df = build_dataset()
    df.to_csv(DATA_DIR / "photo_training_features.csv", index=False)

    x_train, x_test, y_train, y_test = train_test_split(
        df[FEATURE_ORDER], df["label"], test_size=0.2, random_state=42, stratify=df["label"]
    )

    model = RandomForestClassifier(n_estimators=250, random_state=42, class_weight="balanced")
    model.fit(x_train, y_train)
    preds = model.predict(x_test)
    report = classification_report(y_test, preds)

    joblib.dump(model, ARTIFACT_DIR / "photo_verifier.joblib")
    (ARTIFACT_DIR / "training_report.txt").write_text(report, encoding="utf-8")
    print("Saved artifacts to", ARTIFACT_DIR)


if __name__ == "__main__":
    main()
