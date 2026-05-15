from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

import numpy as np
import torch
from PIL import Image
from sklearn.metrics import accuracy_score, classification_report
from sklearn.model_selection import train_test_split
from torch import nn
from torch.utils.data import DataLoader, Dataset
from torchvision import models, transforms

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from shared.cv_grid_crop import detect_grid_bounds

BASE_DIR = Path(__file__).resolve().parent
ARTIFACT_DIR = BASE_DIR / "artifacts"
DATA_DIR = BASE_DIR / "data"
PROCESSED_DIR = DATA_DIR / "processed"
DEFAULT_SOURCE_DIR = BASE_DIR / "wool"

IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".bmp", ".webp"}
INPUT_SIZE = 224
IMAGENET_MEAN = [0.485, 0.456, 0.406]
IMAGENET_STD = [0.229, 0.224, 0.225]
CLASS_NAMES = ["new", "slightly", "moderate", "bad", "unusable"]


class WoolTileDataset(Dataset[tuple[torch.Tensor, int]]):
    def __init__(
        self,
        samples: list[tuple[Path, int]],
        transform: transforms.Compose,
    ) -> None:
        self.samples = samples
        self.transform = transform

    def __len__(self) -> int:
        return len(self.samples)

    def __getitem__(self, idx: int) -> tuple[torch.Tensor, int]:
        path, label = self.samples[idx]
        with Image.open(path) as image:
            image = image.convert("RGB")
            tensor = self.transform(image)
        return tensor, label


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


def _save_grid_tiles(
    image: Image.Image,
    output_dir: Path,
    stem: str,
    grid_size: int,
) -> tuple[int, dict[str, object]]:
    detection = detect_grid_bounds(image, grid_size=grid_size)
    xs = detection.x_bounds
    ys = detection.y_bounds

    count = 0
    for row in range(grid_size):
        for col in range(grid_size):
            left, right = int(xs[col]), int(xs[col + 1])
            top, bottom = int(ys[row]), int(ys[row + 1])
            tile = image.crop((left, top, right, bottom))
            tile.save(output_dir / f"{stem}_r{row + 1}_c{col + 1}.png")
            count += 1
    return count, detection.meta


def preprocess_source_images(source_dir: Path, grid_size: int) -> dict[str, object]:
    if not source_dir.exists():
        raise FileNotFoundError(f"Wool source folder not found: {source_dir}")

    _reset_processed_dir()
    summary: dict[str, object] = {class_name: 0 for class_name in CLASS_NAMES}
    summary["source_images"] = 0
    summary["skipped_images"] = 0
    summary["grid_size"] = grid_size
    summary["grid_method"] = "cv_seam_detection_v1"
    summary["detection"] = {}

    for image_path in sorted(source_dir.iterdir()):
        if not image_path.is_file() or image_path.suffix.lower() not in IMAGE_EXTENSIONS:
            continue

        label = _infer_label_from_name(image_path.stem)
        if not label:
            summary["skipped_images"] = int(summary["skipped_images"]) + 1
            continue

        with Image.open(image_path) as image:
            cropped = _trim_white_and_zoom_in(image, zoom_ratio=0.96)
            tile_count, detection_meta = _save_grid_tiles(cropped, PROCESSED_DIR / label, image_path.stem, grid_size=grid_size)

        summary[label] = int(summary[label]) + int(tile_count)
        summary["source_images"] = int(summary["source_images"]) + 1
        detection_map = dict(summary["detection"])
        detection_map[image_path.name] = detection_meta
        summary["detection"] = detection_map

    return summary


def _build_model(num_classes: int) -> nn.Module:
    model = models.resnet18(weights=models.ResNet18_Weights.DEFAULT)
    for param in model.parameters():
        param.requires_grad = False
    model.fc = nn.Linear(model.fc.in_features, num_classes)
    return model


def train_model() -> dict[str, float | int]:
    class_to_idx = {name: idx for idx, name in enumerate(CLASS_NAMES)}
    samples: list[tuple[Path, int]] = []

    for class_name in CLASS_NAMES:
        for file_path in sorted((PROCESSED_DIR / class_name).glob("*.png")):
            samples.append((file_path, class_to_idx[class_name]))

    if len(samples) < 20:
        raise ValueError("Not enough tile samples to train wool classifier.")

    labels = np.array([label for _, label in samples], dtype=int)
    indices = np.arange(len(samples))
    idx_train, idx_test = train_test_split(
        indices,
        test_size=0.2,
        random_state=42,
        stratify=labels,
    )

    train_transform = transforms.Compose(
        [
            transforms.RandomResizedCrop(INPUT_SIZE, scale=(0.8, 1.0)),
            transforms.RandomHorizontalFlip(0.5),
            transforms.ToTensor(),
            transforms.Normalize(IMAGENET_MEAN, IMAGENET_STD),
        ]
    )
    eval_transform = transforms.Compose(
        [
            transforms.Resize((INPUT_SIZE, INPUT_SIZE)),
            transforms.ToTensor(),
            transforms.Normalize(IMAGENET_MEAN, IMAGENET_STD),
        ]
    )

    train_samples = [samples[int(i)] for i in idx_train]
    test_samples = [samples[int(i)] for i in idx_test]

    train_loader = DataLoader(WoolTileDataset(train_samples, train_transform), batch_size=16, shuffle=True)
    test_loader = DataLoader(WoolTileDataset(test_samples, eval_transform), batch_size=16, shuffle=False)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = _build_model(num_classes=len(CLASS_NAMES)).to(device)
    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.AdamW(model.fc.parameters(), lr=3e-4, weight_decay=1e-4)

    model.train()
    for _ in range(12):
        for batch_x, batch_y in train_loader:
            batch_x = batch_x.to(device)
            batch_y = batch_y.to(device)
            optimizer.zero_grad()
            loss = criterion(model(batch_x), batch_y)
            loss.backward()
            optimizer.step()

    model.eval()
    y_true: list[int] = []
    y_pred: list[int] = []
    with torch.no_grad():
        for batch_x, batch_y in test_loader:
            logits = model(batch_x.to(device))
            preds = logits.argmax(dim=1).cpu().numpy()
            y_pred.extend(preds.tolist())
            y_true.extend(batch_y.numpy().tolist())

    y_true_np = np.array(y_true, dtype=int)
    y_pred_np = np.array(y_pred, dtype=int)

    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    torch.save(model.state_dict(), ARTIFACT_DIR / "wool_classifier_model.pt")

    model_config = {
        "architecture": "resnet18",
        "input_size": INPUT_SIZE,
        "mean": IMAGENET_MEAN,
        "std": IMAGENET_STD,
        "classes": CLASS_NAMES,
        "feature_version": "resnet18_wool_tiles_v2_cv_grid",
    }
    (ARTIFACT_DIR / "model_config.json").write_text(
        json.dumps(model_config, indent=2), encoding="utf-8"
    )

    metrics: dict[str, float | int] = {
        "accuracy": float(accuracy_score(y_true_np, y_pred_np)),
        "train_rows": int(len(idx_train)),
        "test_rows": int(len(idx_test)),
        "num_classes": len(CLASS_NAMES),
    }
    report = classification_report(
        y_true_np,
        y_pred_np,
        target_names=CLASS_NAMES,
        output_dict=True,
        zero_division=0,
    )
    (ARTIFACT_DIR / "training_report.json").write_text(
        json.dumps({"metrics": metrics, "classification_report": report}, indent=2), encoding="utf-8"
    )

    return metrics


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Train wool on skin classifier with CV-aware grid cropping.")
    parser.add_argument("--source-dir", type=Path, default=None, help="Directory containing source collage images.")
    parser.add_argument("--grid-size", type=int, choices=[4, 5], default=int(os.environ.get("WOOL_GRID_SIZE", "5")))
    parser.add_argument("--preprocess-only", action="store_true", help="Only generate cropped tiles and dataset manifest.")
    return parser.parse_args()


def main() -> None:
    torch.manual_seed(42)
    np.random.seed(42)

    args = _parse_args()
    env_source_dir = Path(os.environ.get("WOOL_SOURCE_DIR", str(DEFAULT_SOURCE_DIR)))
    source_dir = (args.source_dir or env_source_dir).resolve()

    prep_summary = preprocess_source_images(source_dir, grid_size=args.grid_size)

    metrics: dict[str, float | int] = {}
    if not args.preprocess_only:
        metrics = train_model()

    manifest = {
        "source_dir": str(source_dir),
        "processed_dir": str(PROCESSED_DIR),
        "classes": CLASS_NAMES,
        "tiles": prep_summary,
    }
    (DATA_DIR / "dataset_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    print("Prepared wool tiles:", json.dumps(prep_summary, indent=2))
    if args.preprocess_only:
        print("Preprocess-only mode complete.")
    else:
        print("Metrics:", json.dumps(metrics, indent=2))


if __name__ == "__main__":
    main()
