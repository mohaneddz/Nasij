# Translation Service

Detachable multilingual message translation microservice (offline retrieval model).

## LLM mode (Groq)

- If `GROQ_API_KEY` or `GROQ_API` is set (env or `backend/.env`), the service tries Groq translation first.
- If Groq is unavailable or key is invalid, it falls back to the local retrieval translator automatically.

## Train

```bash
python train.py
```

## Run

```bash
uvicorn app.main:app --reload --port 8105
```

## Endpoint

- `POST /translate`
