# Sheep Breed Classifier Service

Detachable MVP microservice that operationalizes the sheep image model from service-local data.

## What it does

- Trains a breed classifier from local sheep image folders in `data/sheep_dataset/*`.
- Serves image-based breed inference with confidence and top-k labels.
- Keeps model artifacts locally in this service folder.

## Train

```bash
python train.py
```

## Run

```bash
uvicorn app.main:app --reload --port 8110
```

## Endpoints

- `GET /health`
- `GET /breeds`
- `POST /predict-breed` (multipart: `file`, optional `top_k`)
