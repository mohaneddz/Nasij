from pydantic import BaseModel, Field


class TranslatePayload(BaseModel):
    text: str = Field(min_length=1)
    target_lang: str = Field(default="fr")
    source_lang: str = Field(default="auto")


class TranslateResponse(BaseModel):
    source_lang: str
    target_lang: str
    translated_text: str
    confidence: float
    backend: str

