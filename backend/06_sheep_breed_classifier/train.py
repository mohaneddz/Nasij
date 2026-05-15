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
ARTIFACT_DIR = BASE_DIR / "artifacts"
DATA_DIR = BASE_DIR / "data"

IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".bmp", ".webp"}
INPUT_SIZE = 224
IMAGENET_MEAN = [0.485, 0.456, 0.406]
IMAGENET_STD = [0.229, 0.224, 0.225]


class SheepDataset(Dataset[tuple[torch.Tensor, int]]):
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


def _collect_samples(dataset_root: Path) -> tuple[list[tuple[Path, int]], list[str]]:
    class_dirs: list[Path] = []
    for child in sorted(dataset_root.iterdir()):
        if not child.is_dir():
            continue
        if child.name.lower().startswith("artifacts"):
            continue
        has_images = any(p.suffix.lower() in IMAGE_EXTENSIONS for p in child.iterdir() if p.is_file())
        if has_images:
            class_dirs.append(child)

    if len(class_dirs) < 2:
        raise ValueError(f"Expected at least 2 breed folders in {dataset_root}.")

    samples: list[tuple[Path, int]] = []
    breed_names = [d.name for d in class_dirs]

    for class_index, class_dir in enumerate(class_dirs):
        for file_path in sorted(class_dir.iterdir()):
            if not file_path.is_file() or file_path.suffix.lower() not in IMAGE_EXTENSIONS:
                continue
            samples.append((file_path, class_index))

    if len(samples) < 16:
        raise ValueError("Not enough images to train sheep model. Need at least 16 samples.")

    return samples, breed_names


def _build_resnet18(num_classes: int, train_backbone: bool) -> nn.Module:
    model = models.resnet18(weights=models.ResNet18_Weights.DEFAULT)
    if not train_backbone:
        for param in model.parameters():
            param.requires_grad = False
    model.fc = nn.Linear(model.fc.in_features, num_classes)
    return model


def _load_best_vit_test_accuracy(dataset_root: Path) -> float | None:
    candidates = [
        dataset_root / "artifacts_vit_experiments" / "experiment_results.json",
        dataset_root / "artifacts_vit_color_focus" / "experiment_results.json",
    ]
    scores: list[float] = []
    for candidate in candidates:
        if not candidate.exists():
            continue
        try:
            raw = json.loads(candidate.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        if not isinstance(raw, list):
            continue
        for item in raw:
            if isinstance(item, dict) and "test_acc" in item:
                try:
                    scores.append(float(item["test_acc"]))
                except (TypeError, ValueError):
                    continue
    if not scores:
        return None
    return float(max(scores))


def main() -> None:
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    dataset_root = DATA_DIR / "sheep_dataset"
    torch.manual_seed(42)
    np.random.seed(42)

    samples, breed_names = _collect_samples(dataset_root)
    labels = np.array([label for _, label in samples], dtype=int)
    indices = np.arange(len(samples))

    idx_train, idx_test = train_test_split(
        indices,
        test_size=0.25,
        random_state=42,
        stratify=labels,
    )

    train_transform = transforms.Compose(
        [
            transforms.RandomResizedCrop(INPUT_SIZE, scale=(0.75, 1.0)),
            transforms.RandomHorizontalFlip(p=0.5),
            transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.15),
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

    train_dataset = SheepDataset(train_samples, transform=train_transform)
    test_dataset = SheepDataset(test_samples, transform=eval_transform)

    train_loader = DataLoader(train_dataset, batch_size=16, shuffle=True, num_workers=0)
    test_loader = DataLoader(test_dataset, batch_size=16, shuffle=False, num_workers=0)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = _build_resnet18(num_classes=len(breed_names), train_backbone=False).to(device)

    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.AdamW(model.fc.parameters(), lr=3e-4, weight_decay=1e-4)

    epochs = 18
    model.train()
    for _ in range(epochs):
        for batch_x, batch_y in train_loader:
            batch_x = batch_x.to(device)
            batch_y = batch_y.to(device)
            optimizer.zero_grad()
            logits = model(batch_x)
            loss = criterion(logits, batch_y)
            loss.backward()
            optimizer.step()

    model.eval()
    preds_list: list[int] = []
    y_true_list: list[int] = []
    with torch.no_grad():
        for batch_x, batch_y in test_loader:
            batch_x = batch_x.to(device)
            logits = model(batch_x)
            preds = logits.argmax(dim=1).cpu().numpy()
            preds_list.extend(preds.tolist())
            y_true_list.extend(batch_y.numpy().tolist())

    y_test = np.array(y_true_list, dtype=int)
    preds = np.array(preds_list, dtype=int)
    old_vit_test_acc = _load_best_vit_test_accuracy(dataset_root)
    new_resnet_acc = float(accuracy_score(y_test, preds))

    metrics = {
        "accuracy": new_resnet_acc,
        "train_rows": int(len(idx_train)),
        "test_rows": int(len(idx_test)),
        "num_classes": int(len(breed_names)),
        "old_vit_best_test_accuracy": old_vit_test_acc,
        "new_resnet_test_accuracy": new_resnet_acc,
        "accuracy_change_resnet_minus_vit": (
            None if old_vit_test_acc is None else float(new_resnet_acc - old_vit_test_acc)
        ),
    }

    report = classification_report(
        y_test,
        preds,
        labels=list(range(len(breed_names))),
        target_names=breed_names,
        output_dict=True,
        zero_division=0,
    )

    torch.save(model.state_dict(), ARTIFACT_DIR / "sheep_breed_model.pt")

    model_config = {
        "architecture": "resnet18",
        "input_size": INPUT_SIZE,
        "mean": IMAGENET_MEAN,
        "std": IMAGENET_STD,
        "breed_names": breed_names,
        "feature_version": "resnet18_imagenet_head_only_v1",
    }
    (ARTIFACT_DIR / "model_config.json").write_text(
        json.dumps(model_config, indent=2), encoding="utf-8"
    )

    class_to_idx = {name: idx for idx, name in enumerate(breed_names)}
    (ARTIFACT_DIR / "class_to_idx.json").write_text(
        json.dumps(class_to_idx, indent=2), encoding="utf-8"
    )

    training_report = {"metrics": metrics, "classification_report": report}
    (ARTIFACT_DIR / "training_report.json").write_text(
        json.dumps(training_report, indent=2), encoding="utf-8"
    )

    sample_manifest = {
        "dataset_root": str(dataset_root),
        "classes": breed_names,
        "rows": int(len(samples)),
    }
    (DATA_DIR / "dataset_manifest.json").write_text(
        json.dumps(sample_manifest, indent=2), encoding="utf-8"
    )

    print("Saved sheep model artifacts to", ARTIFACT_DIR)
    print("Metrics:", json.dumps(metrics, indent=2))


if __name__ == "__main__":
    main()
