from pydantic import BaseModel


class AssistPayload(BaseModel):
    message: str


class AssistResponse(BaseModel):
    intent: str
    confidence: float
    extracted_fields: dict[str, str | float | int | list[str] | None]
    reply: str
    backend: str
