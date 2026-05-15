# Business Plan - Nasij

## 1. Executive Summary

### 1.1 Description

Nasij is a mobile-first, offline-capable traceability and operations platform for Algeria's wool value chain. It is designed to cover the complete chain (collection, depot, wash, transformation, commercialization), with execution priority on collection because this is where most control failures start [S01](./sources.md#s01).

The product strategy is not "digitize forms". It is to build a control layer that can:

- preserve lot identity end-to-end,
- expose discrepancies early,
- reduce avoidable material and information loss,
- provide audit-ready records for managers and partners.

### 1.2 Business Objective (5-year)

1. Establish reliable collection-stage digital control in 3 wilayas in Year 1 [A01](./assumptions.md#a01).
2. Scale active source nodes from 420 (Y1) to 1,395 (Y5) [A02](./assumptions.md#a02), [A11](./assumptions.md#a11).
3. Improve discrepancy rate from 14% of missions in Y1 to 8% in Y5 [A13](./assumptions.md#a13).
4. Reach annual operating break-even in Year 5 (base case) [A37](./assumptions.md#a37).

### 1.3 Why Now

- Mobile and internet access are high enough for operational digitization at scale [S06](./sources.md#s06), [S07](./sources.md#s07), [S11](./sources.md#s11), [S12](./sources.md#s12).
- Agriculture remains a meaningful part of national economic activity [S09](./sources.md#s09).
- The challenge requires exactly this type of stage-linked visibility and collection-first rigor [S01](./sources.md#s01).

## 2. Company Overview and Positioning

### 2.1 Operating Position

Nasij is positioned as a B2B/B2B2B operations platform serving chain participants, not a consumer marketplace.

Core differentiation:

- collection-stage data quality controls,
- mandatory QR lot identity,
- discrepancy workflow orchestration,
- offline-first data capture and replay.

### 2.2 Regulatory Position

Nasij handles identifiable operational and actor data; therefore data processing must align with Law 18-07 and related governance arrangements [S16](./sources.md#s16), [S17](./sources.md#s17), [S18](./sources.md#s18).

## 3. Product and Service Model

### 3.1 Service Scope

Nasij provides four linked service layers:

1. Collection orchestration and intake controls.
2. Stage transition tracking (D0->D1->D2->D3/D4).
3. Alerting and discrepancy governance.
4. Reporting, traceability evidence, and compliance support.

Detailed service definitions are in [services.md](./services.md).

### 3.2 Product Requirements that Drive Value

- Collection-first workflow speed and reliability [S01](./sources.md#s01).
- Offline-first operation for variable connectivity zones [S08](./sources.md#s08), [S20](./sources.md#s20).
- Low-friction mobile UX aligned with national mobile usage context [S11](./sources.md#s11), [S14](./sources.md#s14).

## 4. Market and Demand Context

### 4.1 Macro Context

- Population: 46.8M [S02](./sources.md#s02).
- GDP per capita: USD 5,752.99 [S03](./sources.md#s03).
- Inflation: 4.046% [S05](./sources.md#s05).
- Youth unemployment: 29.444% [S04](./sources.md#s04).

Implication: buyers and operators are cost-sensitive; pricing must be tied to measurable operational outcomes.

### 4.2 Digital Access Context

- 54.8M cellular connections in 2025 [S11](./sources.md#s11).
- 36.2M internet users in 2025 [S12](./sources.md#s12).
- Median mobile speed 23.42 Mbps, fixed speed 15.05 Mbps [S14](./sources.md#s14).

Implication: digital adoption is viable, but platform design must stay bandwidth-efficient and offline-resilient.

## 5. Operating Strategy (Pilot to Scale)

### 5.1 Phase 1 - Control the Entry Point

- Standardize declaration schema.
- Force QR tagging at collection.
- Capture gross weight and variance checks at pickup.
- Route critical alerts to control tower.

### 5.2 Phase 2 - Stage Continuity

- Link depot, wash, and transformation records to a single lot lineage.
- Measure stage yields and detect outlier losses.

### 5.3 Phase 3 - Commercial Intelligence

- Provide buyer-facing lot evidence packs.
- Publish KPI dashboards: discrepancy rate, cycle times, coverage, replay success.

## 6. Revenue Model

Revenue is modeled through operational service lines:

1. Per-kg traceability/processing fee [A08](./assumptions.md#a08).
2. Per-mission logistics coordination fee [A09](./assumptions.md#a09).
3. Per-event discrepancy handling fee [A10](./assumptions.md#a10).
4. Reporting and analytics add-ons (later-stage contracts) [A31](./assumptions.md#a31).

### 6.1 Base-case Demand Drivers

- Active source nodes [A02](./assumptions.md#a02), [A11](./assumptions.md#a11).
- Declared volume per source [A03](./assumptions.md#a03).
- Realization ratio [A04](./assumptions.md#a04).
- Missions per source [A12](./assumptions.md#a12).

## 7. Financial Plan (Base Case)

### 7.1 Core Projection Inputs

| Input | Value |
|---|---:|
| Y1 active sources | 420 |
| Y1 avg declared volume per source | 170 kg/year |
| Realization ratio | 88% |
| Y1 per-kg traceability fee | 220 DZD/kg |
| Y1 logistics fee per mission | 2,800 DZD |
| Y1 alert handling fee | 900 DZD |
| Annual price escalation | 3% |
| Annual cost escalation | 4% |

Anchors: [A02](./assumptions.md#a02), [A03](./assumptions.md#a03), [A04](./assumptions.md#a04), [A08](./assumptions.md#a08), [A09](./assumptions.md#a09), [A10](./assumptions.md#a10), [A27](./assumptions.md#a27), [A28](./assumptions.md#a28).

### 7.2 Projected Operating Results (DZD)

| Year | Active Sources | Revenue | Operating Cost (incl. reserve) | Operating Profit |
|---|---:|---:|---:|---:|
| Y1 | 420 | 18,001,368 | 41,956,691 | -23,955,323 |
| Y2 | 567 | 25,004,096 | 44,669,698 | -19,665,602 |
| Y3 | 765 | 34,710,504 | 47,905,966 | -13,195,462 |
| Y4 | 1,033 | 48,224,828 | 51,862,604 | -3,637,776 |
| Y5 | 1,395 | 67,006,195 | 56,803,413 | 10,202,782 |

Assumptions used: [A11](./assumptions.md#a11) to [A31](./assumptions.md#a31).

### 7.3 Break-even View

Base-case annual break-even is reached in Year 5 [A37](./assumptions.md#a37).

## 8. Scenario View

Scenario multipliers:

- Conservative: revenue x0.82, cost x1.09 [A33](./assumptions.md#a33), [A34](./assumptions.md#a34).
- Upside: revenue x1.18, cost x1.04 [A35](./assumptions.md#a35), [A36](./assumptions.md#a36).

| Year | Conservative Profit | Base Profit | Upside Profit |
|---|---:|---:|---:|
| Y1 | -30,971,671 | -23,955,323 | -22,393,344 |
| Y2 | -28,186,612 | -19,665,602 | -16,951,653 |
| Y3 | -23,754,890 | -13,195,462 | -8,863,810 |
| Y4 | -16,985,880 | -3,637,776 | 2,968,189 |
| Y5 | -6,970,640 | 10,202,782 | 19,991,760 |

## 9. Risk Assessment and Mitigation

### 9.1 Operational Risks

- Weak collection execution can degrade all downstream data quality [S01](./sources.md#s01).
- Connectivity gaps can delay record synchronization [S08](./sources.md#s08), [S15](./sources.md#s15).

Mitigation:

- Mandatory collection controls and QR at intake.
- Offline outbox with replay monitoring [A16](./assumptions.md#a16), [A17](./assumptions.md#a17).

### 9.2 Commercial Risks

- Buyers can pressure pricing unless Nasij demonstrates measurable value.

Mitigation:

- KPI-linked commercial model and quarterly value reporting.
- Use discrepancy reduction and traceability coverage as contract anchors [A40](./assumptions.md#a40).

### 9.3 Compliance Risks

- Personal-data handling errors can create legal and reputational exposure [S16](./sources.md#s16), [S17](./sources.md#s17).

Mitigation:

- Role-based access, retention policies, consent records, and audit logs.

## 10. KPI Framework

### 10.1 Core Operational KPIs

- Collection completion rate.
- Declaration-to-collection variance distribution.
- D0->D1->D2 yield progression.
- Alert incidence and closure SLA.
- Offline queue replay success (24h).

### 10.2 Business KPIs

- Revenue per processed kg.
- Gross margin progression.
- Retention of contracted buyers [A20](./assumptions.md#a20).
- Time to break-even [A37](./assumptions.md#a37).

## 11. Implementation Priorities

1. Stabilize collection controls and alert logic first.
2. Complete stage-link continuity and lineage evidence.
3. Harden offline and replay reliability.
4. Formalize compliance and governance controls.
5. Expand contracts using KPI-backed proof of reduced loss and improved visibility.

## 12. Linked Supporting Documents

- [Porter 5+1](./porter.md)
- [PESTEL Analysis](./pestel.md)
- [Empathy Card](./empathy-card.md)
- [Business Model Canvas](./bmc.md)
- [Services Overview](./services.md)
- [Assumptions Register](./assumptions.md)
- [Source Register](./sources.md)
- [Glossary](./glossary.md)

## 13. Source Quality Notes

- Macroeconomic/digital baselines are primarily from World Bank indicator APIs [S02](./sources.md#s02)-[S10](./sources.md#s10), [S15](./sources.md#s15).
- 2025 digital behavior headlines are from DataReportal's country report [S11](./sources.md#s11)-[S14](./sources.md#s14).
- Legal baseline is tied to Law 18-07 and linked legal records [S16](./sources.md#s16)-[S18](./sources.md#s18).
- Domain-specific flow logic is grounded in the challenge brief and current repository docs [S01](./sources.md#s01), [S19](./sources.md#s19), [S20](./sources.md#s20).
