# Services Feature Map

This document explains the **features** used by each backend AI service: what they represent, how they are computed, and how they influence output.

## 01 Traceability Alerts

This service scores the risk level of a wool lot by comparing weight transitions across the supply chain (announced, collected, received, washed, transformed, sold), then combines ML probability with fixed business rules to produce a risk score, human-readable reasons, and a recommended action for operators.

Service path: `backend/01_traceability_alerts`

Primary endpoint: `POST /score`

### Input fields

- `announced_weight_kg`: declared lot weight at announcement.
- `collected_weight_kg`: measured at collection.
- `received_weight_kg`: measured at depot reception.
- `washed_weight_kg`: post-wash weight.
- `transformed_weight_kg`: post-transformation weight.
- `sold_weight_kg`: sold quantity.
- `edit_count`: number of record edits.
- `has_photo`: whether image evidence exists.
- `has_location_update`: whether movement location was updated.
- `actor_history_risk`: prior risk score for actor in `[0,1]`.

### Engineered ML features (`feature_engineering.py`)

- `mismatch_collected_vs_announced = (collected - announced) / announced`
- `loss_collected_to_received = (collected - received) / collected`
- `loss_received_to_washed = (received - washed) / received`
- `loss_washed_to_transformed = (washed - transformed) / washed`
- `loss_transformed_to_sold = (transformed - sold) / transformed`
- `edit_count` (numeric)
- `missing_photo` (`1` if no photo else `0`)
- `missing_location` (`1` if no location update else `0`)
- `actor_history_risk` (numeric)

### How they affect output

- ML model outputs base fraud/anomaly probability.
- Rule engine adds explainable reasons using fixed thresholds (40% mismatch, 25% reception drop, 30% washing loss, etc.).
- Final risk score = `ml_score + rule_boost`, where each extra rule contributes `+0.05` (capped at 1.0).

## 02 Photo Verification

This service checks whether an uploaded image likely contains wool and whether the image quality is good enough for automated decisions, returning wool/not-wool confidence, a rough photo type label, and a human-review flag when blur or uncertainty is high.

Service path: `backend/02_photo_verification`

Primary endpoint: `POST /verify` (multipart file)

### Extracted image features (`image_features.py`)

- `brightness_mean`: average grayscale brightness (normalized).
- `brightness_std`: brightness variability.
- `saturation_mean`: average color saturation.
- `edge_density`: proxy for sharpness/texture complexity.
- `entropy`: image information richness.
- `color_variance`: RGB variance (color spread).

### Derived checks (`photo_checks.py`)

- `blur_score`: scaled from `edge_density`.
- `photo_type`: heuristic class (`dark_or_unclear`, `wool_closeup_texture`, etc.).
- `review_notes`: heuristics based on darkness, blur, and model confidence.

### How they affect output

- Features feed classifier -> `is_wool` + confidence.
- `needs_human_review = (confidence < 0.6) OR (blur_score < 0.3)`.

## 03 Quality Suggestion

This service predicts wool quality class (`low`, `medium`, or `high`) from cleanliness, contamination, moisture, and reliability signals, then provides practical downstream-use suggestions and caution notes to support processing decisions.

Service path: `backend/03_quality_suggestion`

Primary endpoint: `POST /predict-quality`

### Input features

- `cleanliness_score` (`0..1`)
- `contamination_score` (`0..1`)
- `moisture_warning` (bool -> 0/1)
- `photo_confidence` (`0..1`)
- `actor_reliability` (`0..1`)
- `declared_state` (`raw|washed|sorted|unknown`)

### Engineered feature

- `declared_state_code`: mapped as `raw=0`, `washed=1`, `sorted=2`, unknown/other=`3`.

### How they affect output

- RandomForest classifies into `low|medium|high` quality.
- Notes are policy-based:
- `moisture_warning=true` adds drying recommendation.
- `contamination_score > 0.35` adds sorting recommendation.
- Suggested use list is deterministic by predicted label.

## 04 Chatbot Assistant

This service acts as an intent-based assistant for operational text messages, classifying the user’s intent (for example request creation or route/report questions), extracting basic structured fields from free text, and returning a guided reply template.

Service path: `backend/04_chatbot_assistant`

Primary endpoint: `POST /assist`

### Model features

- Uses TF-IDF text features (`1-2` grams) from input `message`.
- Logistic regression predicts intent.

### Extracted entities (`nlp_utils.py`)

- `estimated_weight_kg`: regex from "kg/kilo/kilogram" patterns.
- `sheep_count`: regex from sheep count tokens.
- `wool_state`: keyword map (raw/dirty/unwashed, washed/clean, sorted).
- `availability`: day token extraction (`today`, `tomorrow`, weekdays).
- `missing_fields`: heuristic if location/photo cues are absent.

### How they affect output

- Intent controls response template.
- Extracted entities are returned in `extracted_fields` and used to build `reply` text.

## 05 Translation

This service performs lightweight multilingual translation using a retrieval-based approach: it detects source language (if set to auto), finds the closest known phrase pair, and returns the best matched translation with a confidence score.

Service path: `backend/05_translation`

Primary endpoint: `POST /translate`

### Language detection features

- Keyword hit counts for each language family:
- French (`fr`), English (`en`), Algerian Arabic translit (`ar_dz`), Tamazight translit (`tz`).

### Translation model features

- Query format: `source->target::lowercased_text`.
- Character-level TF-IDF (`char_wb`, ngram `2..5`).
- Nearest retrieval in vector space returns best known target sentence.

### How they affect output

- Highest cosine-like similarity determines returned translation.
- Confidence is capped similarity score (`0..1`).
- This is retrieval translation, not free-form generation.

## 06 Matching Recommendation

This service ranks candidate actors (such as depots or collectors) for a request by scoring distance, reliability, capacity fit, rating, and quality compatibility, then returns the top recommendations with explanations for why they were selected.

Service path: `backend/06_matching_recommendation`

Primary endpoint: `POST /recommend`

### Candidate-scoring features

For each catalog actor:

- `distance_km`: haversine distance from request point.
- `reliability`: actor reliability score from catalog.
- `rating`: actor rating from catalog.
- `capacity_ratio = min(1, capacity_kg / quantity_kg)`.
- `quality_match`:
- `1.0` exact quality match.
- `0.7` if either side is `medium`.
- `0.4` otherwise.

### How they affect output

- RandomForest outputs recommendation probability score.
- Responses sorted descending by score.
- `reason` field summarizes key scoring contributors.

## 07 Route Planning

This service generates a practical pickup route by ordering stops with a nearest-neighbor heuristic, estimating travel duration segment by segment, and assigning the best depot based on capacity feasibility and final-leg proximity.

Service path: `backend/07_route_planning`

Primary endpoint: `POST /plan-route`

### Planning features

- Pickup ordering uses geometric nearest-neighbor from start point.
- For each segment, duration model uses:
- `distance_km`
- `load_ratio = expected_load / truck_capacity`
- `road_quality_index`

### Depot assignment features

- Candidate depots filtered by `remaining_capacity_kg >= expected_load`.
- Among capable depots, nearest is selected.
- If none are capable, nearest depot overall is selected.

### How they affect output

- Produces ordered stops, ETA minutes, total distance, assigned depot, and expected load.

## 08 Forecasting Dashboard

This service forecasts near-term regional wool supply volume for dashboard use by combining seasonal behavior, region encoding, and weather baselines, then returns expected volume with confidence bounds and high-level driver labels.

Service path: `backend/08_forecasting_dashboard`

Primary endpoint: `POST /forecast`

### Training features

- `year`
- `month`
- `region_code` (mapped from region name)
- `temperature` (monthly mean)
- `precipitation` (monthly mean)

### Inference-time feature construction

- Converts requested `region` to `region_code` via metadata map.
- Uses monthly climatology from metadata:
- `monthly_temperature[month]`
- `monthly_precipitation[month]`
- Predicts one step per month in horizon and sums outputs.

### How they affect output

- Returns expected volume plus uncertainty band using residual std.
- `drivers` are static explanatory labels (seasonality/trend/weather baseline).

## 09 Sales Intelligence

This service forecasts next-year wool exports from historical market indicators, allowing either a historical year baseline or manual feature inputs, and reports both the prediction and which missing inputs were imputed internally.

Service path: `backend/09_sales_intelligence`

Primary endpoint: `POST /forecast-next-year`

### Core feature set (`FEATURE_ORDER`)

- `table35_wool_imports_1000lb`
- `table35_wool_exports_1000lb`
- `table29_raw_wool_imports_1000lb`
- `table28_total_supply_clean_lb_m`
- `table28_mill_use_clean_lb_m`
- `table33_greasy_basis_cents_per_lb`

### Target

- `next_year_wool_exports_1000lb` (shifted from current year exports).

### Feature sourcing behavior

- If `year` provided: load stored historical feature row for that year.
- Optional payload fields override that row.
- If no `year`: use only manual payload feature values.
- Missing values are imputed by `SimpleImputer(strategy="median")` in pipeline.

### How they affect output

- RandomForestRegressor predicts next-year exports.
- Response includes `missing_features_imputed` list and `input_source` mode.

## 10 Sheep Breed Classifier

This service predicts sheep breed from an uploaded image with a ResNet18 classifier and returns the top predicted breed plus top-k alternatives with confidences.

Service path: `backend/10_sheep_breed_classifier`

Primary endpoint: `POST /predict-breed` (multipart file + `top_k`)

### Model features

- Image is resized to `224x224`.
- Input normalized with ImageNet stats (`mean`/`std` from model config).
- ResNet18 logits are converted to probabilities using softmax.

### How they affect output

- ResNet18 returns class probabilities over trained breed labels.
- `predicted_breed` is max-probability class.
- `top_k` returns highest probability classes.
- `feature_version` identifies extraction pipeline version.

## 11 Wool Classifier

This service predicts wool condition classes (`new`, `slightly`, `moderate`, `bad`, `unusable`) using a ResNet18 classifier trained from tiled crops.

Service path: `backend/11_wool_classifier`

Primary endpoint: `POST /predict-wool` (multipart file + `top_k`)

### Training/data features

- Source images come from `backend/11_wool_classifier/wool` and are mapped by filename.
- White borders are removed, then a slight center zoom is applied.
- Each image is split into a `5x5` tile grid; tiles form the training set.

### Model features

- Tile image is resized to `224x224`.
- ImageNet normalization is applied.
- ResNet18 logits are converted to class probabilities.

### How they affect output

- Model returns probabilities for all configured quality classes.
- `predicted_label` is the max-probability class.
- `top_k` returns the highest probability classes.
- `feature_version` identifies the serving model pipeline version.

## 08 Wool CV (Offline Model Track)

This is a non-service CV workflow for wool images: it crops source images into `5x5` tiles and trains a ResNet18 model for CV experimentation.

Service path: `backend/08_wool_cv`

Primary script: `python train.py`

### Training/data features

- Uses `backend/08_wool_cv/data/flux1.png`, `flux2.png`, and `flux3.png`.
- Trims white borders, applies slight center zoom, then tiles each image into `5x5`.
- Produces tiles in `backend/08_wool_cv/data/processed/<class>`.

### Artifacts

- `backend/08_wool_cv/artifacts/flux_resnet_model.pt`
- `backend/08_wool_cv/artifacts/model_config.json`
- `backend/08_wool_cv/artifacts/training_report.json`
- `backend/08_wool_cv/data/dataset_manifest.json`

## 09 Wool ML Dataset Service

This service exposes metadata about the wool ML dataset used for experimentation and analysis.

Service path: `backend/09_wool_ml`

Primary endpoint: `GET /dataset-info`

## Cross-Service Notes

- Services are independent; there is no shared feature store.
- Most models are trained on synthetic/seeded or local curated data in each service folder.
- Feature semantics are tied to current code and may change if training scripts or mappings change.
