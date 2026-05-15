# Wool Classifier Service

Detachable MVP microservice that classifies wool photos into:
- `new`
- `slightly`
- `moderate`
- `bad`
- `unusable`

## What it does

- Uses source images from `./wool` (filename-driven labels) during training.
- Crops white borders, applies slight zoom, then splits each image into 5x5 tiles.
- Trains a ResNet18 classifier and serves image-based inference.

## Train

```bash
python train.py
```

## Run

```bash
uvicorn app.main:app --reload --port 8111
```

## Endpoints

- `GET /health`
- `GET /classes`
- `POST /predict-wool` (multipart: `file`, optional `top_k`)
