# Route Planning Service

Detachable route optimization microservice (greedy baseline + trained duration estimator).

## Train

```bash
python train.py
```

## Run

```bash
uvicorn app.main:app --reload --port 8107
```

## Endpoint

- `POST /plan-route`

