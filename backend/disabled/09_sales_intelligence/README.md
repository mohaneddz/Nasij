# Sales Intelligence Service

Detachable MVP microservice that hosts wool sales forecasting assets directly inside the service.

## What it does

- Trains a regression model from `data/wool_dataset/eda/wool/annual_wool_metrics.csv`.
- Predicts next-year wool export volume (`table35_wool_exports_1000lb`) from current market signals.
- Exposes historical yearly feature snapshots for dashboard use.

## Train

```bash
python train.py
```

## Run

```bash
uvicorn app.main:app --reload --port 8109
```

## Endpoints

- `GET /health`
- `GET /service-info`
- `GET /year/{year}`
- `POST /forecast-next-year`
