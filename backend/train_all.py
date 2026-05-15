from __future__ import annotations

import subprocess
import sys
from pathlib import Path

SERVICES = [
    "01_traceability_alerts",
    "02_photo_verification",
    "03_translation",
    "04_matching_recommendation",
    "05_forecasting_tool",
    "06_sheep_breed_classifier",
    "07_wool_on_skin_classifier",
    "08_wool_cv",
]


def main() -> None:
    base = Path(__file__).resolve().parent
    for service in SERVICES:
        service_dir = base / service
        print(f"\n=== Training {service} ===")
        subprocess.run([sys.executable, "train.py"], cwd=service_dir, check=True)
    print("\nAll services trained successfully.")


if __name__ == "__main__":
    main()
