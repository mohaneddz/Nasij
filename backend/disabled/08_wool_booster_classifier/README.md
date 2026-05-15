# Wool Booster Classifier Service

Detachable microservice that classifies wool photos into:
- `new`
- `slightly`
- `moderate`
- `bad`
- `unusable`

The trainer evaluates multiple boosting models (`XGBoost`, `LightGBM`, plus sklearn boosting baselines),
selects the best by validation macro-F1, and saves the winning artifact.

## Train

```bash
python train.py
```

## Run

```bash
uvicorn app.main:app --reload --port 8112
```

## Endpoints

- `GET /health`
- `GET /classes`
- `GET /model-info`
- `POST /predict-wool` (multipart: `file`, optional `top_k`)

