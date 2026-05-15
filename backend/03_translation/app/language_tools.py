from __future__ import annotations


def detect_language(text: str) -> str:
    t = text.lower()
    french_hits = sum(1 for w in ["bonjour", "laine", "ramassage", "depot", "propre"] if w in t)
    english_hits = sum(1 for w in ["hello", "wool", "pickup", "depot", "clean"] if w in t)
    darija_hits = sum(1 for w in ["salam", "souf", "nqiya", "ghodwa", "win"] if w in t)
    tamazight_hits = sum(1 for w in ["azul", "adlis", "aman", "axxam"] if w in t)

    scores = {"fr": french_hits, "en": english_hits, "ar_dz": darija_hits, "tz": tamazight_hits}
    best_lang = max(scores, key=scores.get)
    return best_lang if scores[best_lang] > 0 else "en"

