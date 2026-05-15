from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from shared.cv_grid_crop import detect_grid_bounds

IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".bmp", ".webp"}
DEFAULT_SOURCE_DIR = Path(__file__).resolve().parent / "data" / "raw_collages"
DEFAULT_OUTPUT_DIR = Path(__file__).resolve().parent / "data" / "sheep_dataset"


def _iter_image_files(folder: Path) -> list[Path]:
    return sorted([p for p in folder.iterdir() if p.is_file() and p.suffix.lower() in IMAGE_EXTENSIONS])


def preprocess_collages(source_dir: Path, output_dir: Path, grid_size: int) -> dict[str, object]:
    if not source_dir.exists():
        raise FileNotFoundError(f"Source folder not found: {source_dir}")

    output_dir.mkdir(parents=True, exist_ok=True)
    summary: dict[str, object] = {
        "source_dir": str(source_dir),
        "output_dir": str(output_dir),
        "grid_size": grid_size,
        "grid_method": "cv_seam_detection_v1",
        "source_images": 0,
        "total_tiles": 0,
        "classes": {},
        "detection": {},
    }

    for image_path in _iter_image_files(source_dir):
        class_name = image_path.stem
        class_dir = output_dir / class_name
        class_dir.mkdir(parents=True, exist_ok=True)

        with Image.open(image_path) as image:
            image = image.convert("RGB")
            detection = detect_grid_bounds(image, grid_size=grid_size)

            count = 0
            for row in range(grid_size):
                for col in range(grid_size):
                    left, right = detection.x_bounds[col], detection.x_bounds[col + 1]
                    top, bottom = detection.y_bounds[row], detection.y_bounds[row + 1]
                    tile = image.crop((left, top, right, bottom))
                    tile.save(class_dir / f"{class_name}_{row}_{col}.png")
                    count += 1

        classes = dict(summary["classes"])
        classes[class_name] = count
        summary["classes"] = classes

        detections = dict(summary["detection"])
        detections[image_path.name] = detection.meta
        summary["detection"] = detections

        summary["source_images"] = int(summary["source_images"]) + 1
        summary["total_tiles"] = int(summary["total_tiles"]) + count

    return summary


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Split sheep breed collages into CV-detected grid tiles.")
    parser.add_argument("--source-dir", type=Path, default=DEFAULT_SOURCE_DIR)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--grid-size", type=int, choices=[4, 5], default=4)
    parser.add_argument("--manifest", type=Path, default=Path(__file__).resolve().parent / "data" / "dataset_manifest.json")
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    summary = preprocess_collages(args.source_dir.resolve(), args.output_dir.resolve(), grid_size=args.grid_size)
    args.manifest.parent.mkdir(parents=True, exist_ok=True)
    args.manifest.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()

