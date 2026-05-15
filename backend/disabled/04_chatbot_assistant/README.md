# Chatbot Assistant Service

Detachable NLP service for farmer/admin assistant intent detection and form field extraction.

## LLM mode (Groq)

- If `GROQ_API_KEY` or `GROQ_API` is set (env or `backend/.env`), the service tries Groq first.
- If Groq is unavailable or key is invalid, it falls back to the local intent model automatically.

## Train

```bash
python train.py
```

## Run

```bash
uvicorn app.main:app --reload --port 8104
```

## Endpoint

- `POST /assist`
