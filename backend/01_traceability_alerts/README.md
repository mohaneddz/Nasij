# Traceability Alerts Service

Detachable MVP microservice for lot mismatch risk scoring.

## Train

```bash
python train.py
```

## Run

```bash
uvicorn app.main:app --reload --port 8101
```

## Endpoint

- `POST /score`: returns `risk_score`, reasons, and an action suggestion.

