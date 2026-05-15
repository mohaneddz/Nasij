# Quality Suggestion Service

Detachable quality-grade predictor and transformation-use recommender.

## Train

```bash
python train.py
```

## Run

```bash
uvicorn app.main:app --reload --port 8103
```

## Endpoint

- `POST /predict-quality`

