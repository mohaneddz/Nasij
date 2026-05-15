from __future__ import annotations

import io
from itertools import permutations
from pathlib import Path
import zipfile

import joblib
import pandas as pd
import requests
from sklearn.feature_extraction.text import TfidfVectorizer

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
ARTIFACT_DIR = BASE_DIR / "artifacts"


def download_en_fr_pairs(limit: int = 7000) -> list[tuple[str, str]]:
    url = "https://www.manythings.org/anki/fra-eng.zip"
    headers = {"User-Agent": "curl/8.0", "Accept": "*/*"}
    resp = requests.get(url, headers=headers, timeout=45)
    resp.raise_for_status()
    zf = zipfile.ZipFile(io.BytesIO(resp.content))
    txt_name = next(
        (n for n in zf.namelist() if n.endswith(".txt") and not Path(n).name.startswith("_")),
        None,
    )
    if txt_name is None:
        txt_name = next((n for n in zf.namelist() if n.endswith(".txt")), None)
    if txt_name is None:
        raise ValueError("No text file found in downloaded translation zip.")

    pairs: list[tuple[str, str]] = []
    with zf.open(txt_name) as f:
        for raw_line in f:
            line = raw_line.decode("utf-8", errors="ignore").strip()
            if not line:
                continue
            parts = line.split("\t")
            if len(parts) < 2:
                continue
            en = parts[0].strip()
            fr = parts[1].strip()
            if not en or not fr:
                continue
            pairs.append((en, fr))
            if len(pairs) >= limit:
                break
    if len(pairs) < 200:
        raise ValueError("Downloaded EN-FR corpus is too small to train retrieval model.")
    return pairs


def canonical_phrases() -> list[dict[str, str]]:
    return [
        {"en": "I have 30 kg of raw wool", "fr": "J'ai 30 kg de laine brute", "ar_dz": "andi 30 kilo souf kham", "tz": "ghuri 30 kg n uksum amezwaru"},
        {"en": "pickup is possible tomorrow", "fr": "le ramassage est possible demain", "ar_dz": "yemken ramassage ghdwa", "tz": "asdukel yezmer azekka"},
        {"en": "please upload two photos", "fr": "veuillez televerser deux photos", "ar_dz": "rani n7taj zouj tsawer", "tz": "afud ad tesdukklem sin tugniwin"},
        {"en": "quality is medium", "fr": "la qualite est moyenne", "ar_dz": "lqualite mtabla", "tz": "taqla tettwasef d talemmast"},
        {"en": "route assigned to depot 3", "fr": "itineraire assigne au depot 3", "ar_dz": "route t3aynat l depot 3", "tz": "abrid yettusemle i uselway 3"},
        {"en": "high anomaly risk needs review", "fr": "risque d anomalie eleve a verifier", "ar_dz": "kayn risk kbir lazem muraja3a", "tz": "lla yella uqbur afellay i usenqed"},
        {"en": "washed wool accepted", "fr": "laine lavee acceptee", "ar_dz": "souf mghsoul maqboul", "tz": "uksum yettwaseg iqqbel"},
        {"en": "collector is on the way", "fr": "le collecteur est en route", "ar_dz": "jame3 rah fi triq", "tz": "amzuzzu yella deg ubrid"},
        {"en": "depot capacity is almost full", "fr": "la capacite du depot est presque pleine", "ar_dz": "saaat depot qariba t3amer", "tz": "tazmert n uselway tettwacukk"},
        {"en": "translation completed", "fr": "traduction terminee", "ar_dz": "tarjama kmlet", "tz": "tasuqilt tefukk"},
    ]


def build_pairs() -> pd.DataFrame:
    records: list[dict[str, str]] = []
    try:
        en_fr_pairs = download_en_fr_pairs()
    except Exception as exc:
        print(f"[translation] Real EN-FR corpus download failed ({exc}); using only local phrases.")
        en_fr_pairs = []

    for en_text, fr_text in en_fr_pairs:
        records.append(
            {
                "source_lang": "en",
                "target_lang": "fr",
                "source_text": en_text,
                "target_text": fr_text,
                "query_text": f"en->fr::{en_text.lower()}",
            }
        )
        records.append(
            {
                "source_lang": "fr",
                "target_lang": "en",
                "source_text": fr_text,
                "target_text": en_text,
                "query_text": f"fr->en::{fr_text.lower()}",
            }
        )

    for phrase in canonical_phrases():
        languages = list(phrase.keys())
        for src, tgt in permutations(languages, 2):
            records.append(
                {
                    "source_lang": src,
                    "target_lang": tgt,
                    "source_text": phrase[src],
                    "target_text": phrase[tgt],
                    "query_text": f"{src}->{tgt}::{phrase[src].lower()}",
                }
            )
    return pd.DataFrame(records)


def main() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)

    df = build_pairs()
    df.to_csv(DATA_DIR / "translation_pairs.csv", index=False)

    vectorizer = TfidfVectorizer(analyzer="char_wb", ngram_range=(2, 5))
    matrix = vectorizer.fit_transform(df["query_text"])
    meta = df[["target_text"]].rename(columns={"target_text": "target"}).to_dict("records")
    payload = {"vectorizer": vectorizer, "matrix": matrix, "meta": meta}

    joblib.dump(payload, ARTIFACT_DIR / "translator_retrieval.joblib")
    print("Saved artifacts to", ARTIFACT_DIR)


if __name__ == "__main__":
    main()
