# Nasij Services Overview

Nasij is modeled as a traceability-first operational platform for the wool value chain, with collection as the primary control point and end-to-end continuity across depot, wash, transformation, and commercialization [S01](./sources.md#s01), [S19](./sources.md#s19).

## 1. Collection Services (Priority Layer)

### 1.1 Structured Collection Intake

- Digitize source declarations by actor type (C1/C2/C3) with mission scheduling and minimum required metadata.
- Capture collection events with geotag, timestamps, and operator identity.
- Apply QR-based lot identity immediately at intake to preserve downstream continuity [S19](./sources.md#s19).

### 1.2 Weight Capture and Reconciliation Trigger

- Capture gross field weight at collection.
- Reconcile against declaration expectations and push alert workflows when variance exceeds policy thresholds.
- Continue operations while preserving the corrected measured value as canonical for the next stage [S19](./sources.md#s19).

## 2. Depot Services (D1)

### 2.1 Intake Verification and Re-weigh

- Scan inbound lot QR.
- Re-weigh and compare against collection value.
- Produce discrepancy flags and escalation tickets where needed.

### 2.2 Primary Sorting and Pre-clean

- Record contaminant removal and update lot state from `D0` to `D1`.
- Store per-lot handling notes needed for wash-stage planning.

## 3. Wash Services (D2)

### 3.1 Wash Stage Recording

- Register wash completion by lot.
- Capture post-wash weight and quality checkpoints.
- Update state to `D2` with auditable operator and timestamp metadata.

### 3.2 Yield and Loss Visibility

- Quantify D1->D2 mass variation per lot and per period.
- Detect abnormal loss patterns early for process correction.

## 4. Transformation Services (D3/D4)

### 4.1 Transformation Input/Output Ledger

- Register D2 input lots entering transformation.
- Record output classification and commercial destination (D3 / D4).
- Maintain lot lineage to support buyer confidence and quality evidence [S01](./sources.md#s01).

### 4.2 Commercial Readiness Pack

- Export per-lot history and key quality/weight events.
- Provide batch-level compliance and discrepancy history for downstream sales and governance.

## 5. Platform Services

### 5.1 Role-based Mobile Operations

- Mobile-first experience for field and source actors is justified by strong cellular adoption and internet penetration [S06](./sources.md#s06), [S07](./sources.md#s07), [S11](./sources.md#s11), [S12](./sources.md#s12).

### 5.2 Offline-first Capture and Sync

- Local-first recording for low-connectivity conditions, then queued synchronization.
- Prioritized for field contexts where rural and logistics constraints can interrupt real-time operations [S08](./sources.md#s08), [S15](./sources.md#s15), [S20](./sources.md#s20).

### 5.3 Alert and Control Tower

- Standardized anomaly types (mass variance, missing handoff, delayed progression).
- Central dashboard for unresolved risk events and operational bottlenecks.

## 6. Governance and Compliance Services

### 6.1 Data Protection Controls

- Consent-aware data collection, role-based access, and traceable processing logs aligned with Law 18-07 obligations [S16](./sources.md#s16), [S17](./sources.md#s17).

### 6.2 Audit and Accountability

- Immutable event trails for lot progression and operator actions.
- Periodic compliance review process linked to the national authority context [S18](./sources.md#s18).

## 7. Revenue-linked Service Lines (Estimate Model)

- Per-kg traceability/processing service fees [A08](./assumptions.md#a08).
- Pickup/logistics mission fees [A09](./assumptions.md#a09).
- Discrepancy exception handling fees [A10](./assumptions.md#a10).
- Optional advanced analytics and partner reporting packages (modeled in business plan) [A31](./assumptions.md#a31).

Revenue logic and 5-year projections are detailed in [business-plan.md](./business-plan.md).
