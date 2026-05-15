# Forecast Dashboard Service

Detachable synthetic demand forecasting service for MVP dashboard demos.

Synthetic data logic:
- Reads U.S. historical imports and exports from `data/Table 28.csv`
- Builds Algerian annual demand baseline from mostly U.S. imports + small exports adjustment
- Tones down scale for Algeria (smaller market volume)
- Expands annual totals to daily series with light seasonality/noise
- Applies Eid al Adha demand shock each year:
  - 7 days before Eid: ramp down toward ~90% drop
  - Eid day + next 20 days: remain low with small variance

## Train

```bash
python train.py
```

## Run

```bash
uvicorn app.main:app --reload --port 8108
```

## Endpoint

- `POST /forecast`
