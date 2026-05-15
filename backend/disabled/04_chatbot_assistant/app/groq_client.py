from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any

import requests

GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
DEFAULT_MODEL = os.getenv("GROQ_MODEL", "llama-3.1-8b-instant")


def _load_env_file() -> None:
    env_path = Path(__file__).resolve().parents[2] / ".env"
    if not env_path.exists():
        return
    for raw in env_path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()
        if key and key not in os.environ:
            os.environ[key] = value


def get_groq_api_key() -> str | None:
    key = os.getenv("GROQ_API_KEY") or os.getenv("GROQ_API")
    if key:
        return key
    _load_env_file()
    return os.getenv("GROQ_API_KEY") or os.getenv("GROQ_API")


def _extract_json(text: str) -> dict[str, Any] | None:
    text = text.strip()
    if not text:
        return None

    # Plain JSON case.
    try:
        obj = json.loads(text)
        if isinstance(obj, dict):
            return obj
    except json.JSONDecodeError:
        pass

    # Fenced JSON case.
    if "```" in text:
        chunks = text.split("```")
        for chunk in chunks:
            candidate = chunk.strip()
            if candidate.startswith("json"):
                candidate = candidate[4:].strip()
            try:
                obj = json.loads(candidate)
                if isinstance(obj, dict):
                    return obj
            except json.JSONDecodeError:
                continue

    start = text.find("{")
    end = text.rfind("}")
    if start >= 0 and end > start:
        candidate = text[start : end + 1]
        try:
            obj = json.loads(candidate)
            if isinstance(obj, dict):
                return obj
        except json.JSONDecodeError:
            return None
    return None


def chat_json(system_prompt: str, user_prompt: str, timeout: int = 30) -> dict[str, Any] | None:
    api_key = get_groq_api_key()
    if not api_key:
        return None

    payload = {
        "model": DEFAULT_MODEL,
        "temperature": 0.1,
        "max_tokens": 500,
        "response_format": {"type": "json_object"},
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
    }
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    try:
        response = requests.post(GROQ_URL, headers=headers, json=payload, timeout=timeout)
        response.raise_for_status()
        data = response.json()
        text = data["choices"][0]["message"]["content"]
        return _extract_json(text)
    except Exception:
        return None
