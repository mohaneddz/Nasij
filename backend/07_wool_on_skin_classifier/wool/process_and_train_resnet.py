from __future__ import annotations

import json
from pathlib import Path

import numpy as np
import torch
from PIL import Image
from sklearn.metrics import accuracy_score, classification_report
from sklearn.model_selection import train_test_split
from torch import nn
from torch.utils.data import DataLoader, Dataset
from torchvision import models, transforms

BASE_DIR = Path(__file__).resolve().parent
PROCESSED_DIR = BASE_DIR / "processed"
ARTIFACT_DIR = BASE_DIR / "artifacts"
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".bmp", ".webp"}

INPUT_SIZE = 224
IMAGENET_MEAN = [0.485, 0.456, 0.406]
IMAGENET_STD = [0.229, 0.224, 0.225]


class TileDataset(Dataset[tuple[torch.Tensor, int]]):
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
    (PROCESSED_DIR / "new").mkdir(parents=True, exist_ok=True)
    (PROCESSED_DIR / "unusable").mkdir(parents=True, exist_ok=True)


def _infer_label_from_name(stem: str) -> str:
    lower = stem.lower()
    if "new" in lower:
        return "new"
    if "unusable" in lower:
        return "unusable"
    return "unusable"


def _trim_white_and_zoom_in(image: Image.Image, zoom_ratio: float = 0.96) -> Image.Image:
    rgb = image.convert("RGB")
    arr = np.asarray(rgb)

    non_white = np.any(arr < 245, axis=2)
    if np.any(non_white):
        ys, xs = np.where(non_white)
        top, bottom = int(ys.min()), int(ys.max()) + 1
        left, right = int(xs.min()), int(xs.max()) + 1
        rgb = rgb.crop((left, top, right, bottom))

    w, h = rgb.size
    zoom_w = max(1, int(w * zoom_ratio))
    zoom_h = max(1, int(h * zoom_ratio))
    left = max(0, (w - zoom_w) // 2)
    top = max(0, (h - zoom_h) // 2)
    return rgb.crop((left, top, left + zoom_w, top + zoom_h))


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
            tile_path = output_dir / f"{stem}_r{row + 1}_c{col + 1}.png"
            tile.save(tile_path)
            count += 1
    return count


def preprocess_wool_tiles() -> dict[str, int]:
    _reset_processed_dir()
    summary = {"new": 0, "unusable": 0, "source_images": 0}

    for image_path in sorted(BASE_DIR.iterdir()):
        if not image_path.is_file() or image_path.suffix.lower() not in IMAGE_EXTENSIONS:
            continue
        label = _infer_label_from_name(image_path.stem)
        output_dir = PROCESSED_DIR / label

        with Image.open(image_path) as image:
            prepared = _trim_white_and_zoom_in(image, zoom_ratio=0.96)
            tile_count = _save_5x5_tiles(prepared, output_dir, image_path.stem)

        summary[label] += tile_count
        summary["source_images"] += 1

    return summary


def _build_resnet(num_classes: int) -> nn.Module:
    model = models.resnet18(weights=models.ResNet18_Weights.DEFAULT)
    for param in model.parameters():
        param.requires_grad = False
    model.fc = nn.Linear(model.fc.in_features, num_classes)
    return model


def train_classifier() -> dict[str, float | int]:
    classes = ["new", "unusable"]
    class_to_idx = {name: idx for idx, name in enumerate(classes)}

    samples: list[tuple[Path, int]] = []
    for class_name in classes:
        for file_path in sorted((PROCESSED_DIR / class_name).glob("*.png")):
            samples.append((file_path, class_to_idx[class_name]))

    if len(samples) < 20:
        raise ValueError("Not enough tile samples to train classifier.")

    indices = np.arange(len(samples))
    labels = np.array([label for _, label in samples], dtype=int)
    idx_train, idx_test = train_test_split(indices, test_size=0.2, random_state=42, stratify=labels)

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

    train_loader = DataLoader(TileDataset(train_samples, train_transform), batch_size=16, shuffle=True)
    test_loader = DataLoader(TileDataset(test_samples, eval_transform), batch_size=16, shuffle=False)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = _build_resnet(num_classes=2).to(device)
    optimizer = torch.optim.AdamW(model.fc.parameters(), lr=3e-4, weight_decay=1e-4)
    criterion = nn.CrossEntropyLoss()

    model.train()
    for _ in range(12):
        for x, y in train_loader:
            x = x.to(device)
            y = y.to(device)
            optimizer.zero_grad()
            loss = criterion(model(x), y)
            loss.backward()
            optimizer.step()

    model.eval()
    y_true: list[int] = []
    y_pred: list[int] = []
    with torch.no_grad():
        for x, y in test_loader:
            x = x.to(device)
            logits = model(x)
            preds = logits.argmax(dim=1).cpu().numpy()
            y_pred.extend(preds.tolist())
            y_true.extend(y.numpy().tolist())

    y_true_np = np.array(y_true, dtype=int)
    y_pred_np = np.array(y_pred, dtype=int)

    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    torch.save(model.state_dict(), ARTIFACT_DIR / "wool_resnet_model.pt")
    config = {
        "architecture": "resnet18",
        "input_size": INPUT_SIZE,
        "mean": IMAGENET_MEAN,
        "std": IMAGENET_STD,
        "classes": classes,
    }
    (ARTIFACT_DIR / "model_config.json").write_text(json.dumps(config, indent=2), encoding="utf-8")

    metrics: dict[str, float | int] = {
        "accuracy": float(accuracy_score(y_true_np, y_pred_np)),
        "train_rows": int(len(idx_train)),
        "test_rows": int(len(idx_test)),
    }

    report = classification_report(y_true_np, y_pred_np, target_names=classes, output_dict=True, zero_division=0)
    output = {"metrics": metrics, "classification_report": report}
    (ARTIFACT_DIR / "training_report.json").write_text(json.dumps(output, indent=2), encoding="utf-8")

    return metrics


def main() -> None:
    torch.manual_seed(42)
    np.random.seed(42)

    prep_summary = preprocess_wool_tiles()
    metrics = train_classifier()

    print("Prepared wool tiles:", json.dumps(prep_summary, indent=2))
    print("Wool classifier metrics:", json.dumps(metrics, indent=2))


if __name__ == "__main__":
    main()
