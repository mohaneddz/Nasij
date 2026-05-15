from fastapi import FastAPI

from app.llm_assistant import assist_with_groq
from app.modeling import IntentModel
from app.nlp_utils import extract_entities
from app.response_builder import build_reply
from app.schemas import AssistPayload, AssistResponse

app = FastAPI(title="Chatbot Assistant Service", version="0.1.0")
model = IntentModel()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/assist", response_model=AssistResponse)
def assist(payload: AssistPayload) -> AssistResponse:
    llm = assist_with_groq(payload.message)
    if llm is not None:
        return AssistResponse(**llm)

    intent, confidence = model.predict(payload.message)
    extracted = extract_entities(payload.message)
    reply = build_reply(intent, extracted)
    return AssistResponse(
        intent=intent,
        confidence=round(confidence, 4),
        extracted_fields=extracted,
        reply=reply,
        backend="local_intent_model",
    )
