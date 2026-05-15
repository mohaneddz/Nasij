# Photo Verification Service

Detachable MVP computer-vision pre-check service for wool request images.

## Train

```bash
python train.py
```

Training materializes local datasets under `data/`:
- `real_wool` for positive wool images
- `real_non_wool` (or `generated_non_wool` fallback) for negatives

## Run

```bash
uvicorn app.main:app --reload --port 8102
```

## Endpoint

- `POST /verify` with `multipart/form-data` file upload.

Response now includes:
- `is_wool` (binary verifier output)
- `wool_condition` (`NEW`, `SLIGHTLY`, `MODERATE`, `BAD`)
