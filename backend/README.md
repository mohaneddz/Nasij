# MVP AI Services API Guide

This backend contains 12 detachable FastAPI microservices.

## Wool Model Tracks

- `11_wool_classifier`: Skin health classifier (ResNet18 tile-based quality classes).
- `12_wool_cv`: Wool CV workflow (`5x5` tiling + ResNet training artifacts).
- `13_wool_ml`: Wool ML dataset/experimentation assets.

## Services and Ports

- `01_traceability_alerts` -> `http://127.0.0.1:8101`
- `02_photo_verification` -> `http://127.0.0.1:8102`
- `03_quality_suggestion` -> `http://127.0.0.1:8103`
- `04_chatbot_assistant` -> `http://127.0.0.1:8104`
- `05_translation` -> `http://127.0.0.1:8105`
- `06_matching_recommendation` -> `http://127.0.0.1:8106`
- `07_route_planning` -> `http://127.0.0.1:8107`
- `08_forecasting_dashboard` -> `http://127.0.0.1:8108`
- `09_sales_intelligence` -> `http://127.0.0.1:8109`
- `10_sheep_breed_classifier` -> `http://127.0.0.1:8110`
- `11_wool_classifier` -> `http://127.0.0.1:8111`

## Prerequisites

- Python dependencies for each service are installed.
- Service artifacts are generated before inference.
- Data files inside each service `data/` folder exist.

## Start Everything

Train all models/artifacts:

```bash
python train_all.py
```

Run all services:

```bash
python run_all.py
```

## Common Endpoint

Every service exposes:

```bash
curl http://127.0.0.1:<PORT>/health
```

Expected:

```json
{"status":"ok"}
```

## 01 Traceability Alerts (`8101`)

### POST `/score`

```bash
curl -X POST http://127.0.0.1:8101/score \
  -H "Content-Type: application/json" \
  -d '{
    "announced_weight_kg":120,
    "collected_weight_kg":118,
    "received_weight_kg":102,
    "washed_weight_kg":90,
    "transformed_weight_kg":82,
    "sold_weight_kg":80,
    "edit_count":1,
    "has_photo":true,
    "has_location_update":true,
    "actor_history_risk":0.25
  }'
```

Assumptions:

- All weight fields must be non-negative.
- `actor_history_risk` must be in `[0,1]`.
- Output risk combines ML score and rule triggers.
- Rule thresholds are fixed in code:
- `collected > announced` by more than `40%`.
- `received < collected` by more than `25%`.
- `washed` loss from `received` more than `30%`.
- `edit_count >= 3`, missing photo/location, or sold much higher than washed also increase risk.

## 02 Photo Verification (`8102`)

### POST `/verify`

```bash
curl -X POST http://127.0.0.1:8102/verify \
  -F "file=@./sample.png"
```

Assumptions:

- Request must be multipart form-data with `file`.
- Image quality heuristics use handcrafted features.
- `needs_human_review` is true when confidence is low (`<0.6`) or blur is low (`<0.3`).

## 03 Quality Suggestion (`8103`)

### POST `/predict-quality`

```bash
curl -X POST http://127.0.0.1:8103/predict-quality \
  -H "Content-Type: application/json" \
  -d '{
    "cleanliness_score":0.82,
    "contamination_score":0.12,
    "moisture_warning":false,
    "photo_confidence":0.88,
    "actor_reliability":0.90,
    "declared_state":"clean"
  }'
```

Assumptions:

- Scores must be in `[0,1]`.
- `declared_state` is mapped internally (`raw`, `washed`, `sorted`, else `unknown`).
- Service predicts one label from `low|medium|high` and suggested uses.

## 04 Chatbot Assistant (`8104`)

### POST `/assist`

```bash
curl -X POST http://127.0.0.1:8104/assist \
  -H "Content-Type: application/json" \
  -d '{"message":"I have 30 kg of wool tomorrow in Tizi Ouzou"}'
```

Assumptions:

- `message` is required.
- Intent is an ML classifier prediction over trained intent classes.
- Entity extraction is regex/keyword based (weights, sheep count, state, day tokens).
- Missing fields are inferred heuristically, not guaranteed comprehensive.

## 05 Translation (`8105`)

### POST `/translate`

```bash
curl -X POST http://127.0.0.1:8105/translate \
  -H "Content-Type: application/json" \
  -d '{
    "text":"I have clean wool ready for pickup",
    "source_lang":"en",
    "target_lang":"fr"
  }'
```

Assumptions:

- `text` is required and non-empty.
- If `source_lang` is `auto`, detection uses simple keyword matching (`en`, `fr`, `ar_dz`, `tz`).
- Translation uses local retrieval similarity, not a generative translator.
- Unsupported/rare phrasing still returns closest known retrieval candidate.

## 06 Matching Recommendation (`8106`)

### POST `/recommend`

```bash
curl -X POST http://127.0.0.1:8106/recommend \
  -H "Content-Type: application/json" \
  -d '{
    "latitude":36.75,
    "longitude":3.05,
    "quantity_kg":120,
    "required_quality":"medium",
    "actor_type":"depot",
    "top_k":3
  }'
```

Assumptions:

- `quantity_kg > 0`.
- `top_k` in `[1,10]`.
- Catalog comes from local `data/actors_seed.csv`.
- `actor_type` filters rows exactly; unknown actor type returns empty recommendations.

## 07 Route Planning (`8107`)

### POST `/plan-route`

```bash
curl -X POST http://127.0.0.1:8107/plan-route \
  -H "Content-Type: application/json" \
  -d '{
    "start_latitude":36.75,
    "start_longitude":3.05,
    "truck_capacity_kg":900,
    "road_quality_index":0.8,
    "pickups":[
      {"request_id":"req_1","latitude":36.76,"longitude":3.07,"estimated_weight_kg":220},
      {"request_id":"req_2","latitude":36.72,"longitude":3.01,"estimated_weight_kg":180}
    ],
    "depots":[
      {"depot_id":"depot_a","latitude":36.80,"longitude":3.15,"remaining_capacity_kg":1500}
    ]
  }'
```

Assumptions:

- `truck_capacity_kg > 0`, `road_quality_index` in `[0.1,1.0]`.
- Pickup order uses greedy nearest-neighbor, not global optimum routing.
- Expected load is clipped to truck capacity.
- Depot assignment chooses nearest depot that can hold full load; if none can, chooses nearest depot anyway.

## 08 Forecasting Dashboard (`8108`)

### POST `/forecast`

```bash
curl -X POST http://127.0.0.1:8108/forecast \
  -H "Content-Type: application/json" \
  -d '{"region":"Tizi Ouzou","horizon_days":30,"wool_type":"mixed"}'
```

Assumptions:

- `horizon_days` must be in `[7,180]`.
- `region` must exist in the model metadata region map (otherwise `400`).
- Forecast uses monthly weather baseline + historical trend from trained artifacts.
- `wool_type` is accepted but currently not used in model features.

## 09 Sales Intelligence (`8109`)

### GET `/service-info`

```bash
curl http://127.0.0.1:8109/service-info
```

### GET `/year/{year}`

```bash
curl http://127.0.0.1:8109/year/2020
```

### POST `/forecast-next-year`

```bash
curl -X POST http://127.0.0.1:8109/forecast-next-year \
  -H "Content-Type: application/json" \
  -d '{"year":2020}'
```

Example with manual overrides:

```bash
curl -X POST http://127.0.0.1:8109/forecast-next-year \
  -H "Content-Type: application/json" \
  -d '{
    "table35_wool_imports_1000lb":360000,
    "table35_wool_exports_1000lb":60000,
    "table29_raw_wool_imports_1000lb":5800
  }'
```

Assumptions:

- `/year/{year}` only accepts years present in artifacts (`404` otherwise).
- `/forecast-next-year` requires `year` or at least one feature value (`400` if none).
- Missing features are imputed by model pipeline median imputer.
- Input source is reported as `historical_year`, `historical_year_with_overrides`, or `manual_features`.

## 10 Sheep Breed Classifier (`8110`)

### GET `/breeds`

```bash
curl http://127.0.0.1:8110/breeds
```

### POST `/predict-breed`

```bash
curl -X POST http://127.0.0.1:8110/predict-breed \
  -F "file=@./sample.png" \
  -F "top_k=3"
```

Assumptions:

- Request must be multipart form-data.
- `file` must be a non-empty image content type.
- `top_k` must be between `1` and `10`.
- Prediction confidence is from model probabilities over trained classes in local dataset.

## 11 Skin Health Classifier (`8111`)

### GET `/classes`

```bash
curl http://127.0.0.1:8111/classes
```

### POST `/predict-wool`

```bash
curl -X POST http://127.0.0.1:8111/predict-wool \
  -F "file=@./sample.png" \
  -F "top_k=2"
```

Assumptions:

- Request must be multipart form-data.
- `file` must be a non-empty image content type.
- `top_k` must be between `1` and `10`.
- Classes are `new`, `slightly`, `moderate`, `bad`, `unusable`.

## Error Behavior

- `400 Bad Request` is used for invalid payloads or unsupported values.
- `404 Not Found` is used by sales year lookup when year is absent.
- Startup fails with `FileNotFoundError` if required model artifacts are missing; run `python train_all.py`.
