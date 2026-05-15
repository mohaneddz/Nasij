# Matching Recommendation Service

Detachable nearest-depot / nearest-collector recommendation microservice with ML ranking.

## Train

```bash
python train.py
```

## Run

```bash
uvicorn app.main:app --reload --port 8106
```

## Endpoint

- `POST /recommend`

