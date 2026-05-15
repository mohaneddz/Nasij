from fastapi import FastAPI, HTTPException

from app.language_tools import detect_language
from app.llm_translate import translate_with_groq
from app.schemas import TranslatePayload, TranslateResponse

app = FastAPI(title="Translation Service", version="0.2.0")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/translate", response_model=TranslateResponse)
def translate(payload: TranslatePayload) -> TranslateResponse:
    source_lang = payload.source_lang if payload.source_lang != "auto" else detect_language(payload.text)

    llm = translate_with_groq(payload.text, source_lang, payload.target_lang)
    if llm is None:
        raise HTTPException(
            status_code=503,
            detail="Groq translation unavailable. Ensure GROQ_API_KEY is set and API access is working.",
        )

    translated, confidence = llm
    return TranslateResponse(
        source_lang=source_lang,
        target_lang=payload.target_lang,
        translated_text=translated,
        confidence=round(confidence, 4),
        backend="groq_api",
    )
