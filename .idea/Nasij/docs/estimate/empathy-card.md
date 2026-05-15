# Empathy Card - Nasij (Dual Persona)

## Purpose

This empathy card translates Nasij strategy into user-facing behavioral requirements for two critical personas:

1. Upstream source actor (C1/C2/C3) creating collection requests.
2. Internal field operator (collector/depot flow) responsible for traceability continuity.

The market context assumes high mobile reach but non-uniform operating conditions, including rural realities and affordability pressure [S04](./sources.md#s04), [S07](./sources.md#s07), [S08](./sources.md#s08), [S11](./sources.md#s11).

## Persona A - Source Actor (Farmer / Butcher / Third Party)

### 1) What They See

- Fragmented, manual coordination for pickup and follow-up.
- Limited trust in declared-vs-received quantities.
- Economic pressure from inflation and youth/household vulnerability in local contexts [S04](./sources.md#s04), [S05](./sources.md#s05).

### 2) What They Hear

- "Declare quickly, then wait for calls."
- "Weights may change later; no clear record to prove what happened."
- "Digital is growing, but operational reliability still depends on field execution" [S11](./sources.md#s11), [S15](./sources.md#s15).

### 3) What They Think and Feel

- Wants pickup certainty and transparent follow-up.
- Fears unfair deductions or missing records.
- Prefers low-friction mobile interactions over paperwork [S06](./sources.md#s06), [S12](./sources.md#s12).

### 4) What They Say and Do

- "I need to know who is coming and when."
- "Give me proof of what was collected."
- Uses phone-first channels and messaging for operational communication [S11](./sources.md#s11), [S13](./sources.md#s13).

### 5) Pains

- Uncertain mission timing.
- Disputes around quantity and quality handoff.
- Weak transparency once material leaves origin point [S01](./sources.md#s01).

### 6) Gains

- QR-tagged proof at collection.
- Trackable lot status after pickup.
- Faster issue resolution when discrepancy alerts appear.

## Persona B - Internal Operator (Collector + Depot Intake)

### 1) What They See

- High variance in source quality and declaration completeness.
- Time pressure during pickups and handoffs.
- Connectivity variability in field routes [S08](./sources.md#s08), [S15](./sources.md#s15), [S20](./sources.md#s20).

### 2) What They Hear

- "Do not block operations; keep chain moving."
- "Capture reliable data even when offline."
- "Any mismatch must be visible and actionable."

### 3) What They Think and Feel

- Needs simple workflows under operational stress.
- Wants clear exception logic instead of ad-hoc judgment.
- Needs confidence that sync/replay will not lose data.

### 4) What They Say and Do

- "Scan, weigh, confirm, continue."
- "Flag anomalies now, do not wait for post-fact cleanup."
- Uses role-specific screens and status-driven flows [S19](./sources.md#s19), [S20](./sources.md#s20).

### 5) Pains

- Manual reconciliation overhead.
- Repeated data entry when network drops.
- Accountability risk when data lineage is incomplete.

### 6) Gains

- One lot identity from field to sale.
- Automatic discrepancy highlighting.
- Clear audit trail and operator attribution.

## Shared Emotional Drivers

- Fairness: the recorded quantity must be defendable.
- Predictability: actors need reliable sequencing between stages.
- Trust: systems must prove continuity, not just record isolated events.

## Product Implications

1. Collection must be the strongest and fastest workflow in the app [S01](./sources.md#s01), [S19](./sources.md#s19).
2. Offline capture is mandatory, not optional [S08](./sources.md#s08), [S20](./sources.md#s20).
3. Every stage transition needs machine-verifiable lot continuity.
4. Alerts must be actionable with role ownership and SLA targets.
5. Compliance and consent controls should be embedded, not bolted on [S16](./sources.md#s16), [S17](./sources.md#s17).

Business and operating implications are integrated in [business-plan.md](./business-plan.md) and [services.md](./services.md).
