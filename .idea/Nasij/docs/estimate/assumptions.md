# Nasij Assumptions Register

This register captures internal modeling assumptions used across the Nasij estimate documents.
Values are base-case unless explicitly marked otherwise.

## External Baseline Assumptions

| ID | Assumption | Base Value | Rationale |
|---|---|---:|---|
| <a id="a01"></a>A01 | Pilot geography coverage in Year 1 | 3 wilayas | Keeps rollout manageable while covering multiple supply patterns. |
| <a id="a02"></a>A02 | Active source nodes (farmers, butchers, third parties) by end of Year 1 | 420 | Operationally feasible onboarding target for a pilot with field teams. |
| <a id="a03"></a>A03 | Average declared wool volume per active source per year | 170 kg | Conservative blend of small and medium suppliers. |
| <a id="a04"></a>A04 | Declaration-to-collection realization ratio | 88% | Accounts for cancellations, access failures, and no-shows. |
| <a id="a05"></a>A05 | Average gross-to-net reduction during depot prep (D0 to D1) | 12% | Covers impurities and manual sorting losses. |
| <a id="a06"></a>A06 | Average net reduction during wash stage (D1 to D2) | 23% | Reflects moisture and contaminant removal in wash operations. |
| <a id="a07"></a>A07 | Transformation conversion efficiency (D2 to D3/D4 usable output) | 90% | Includes handling and process loss before commercial output. |
| <a id="a08"></a>A08 | Year 1 average traceability service fee | 220 DZD/kg processed | Balanced price point for traceability value and early adoption. |
| <a id="a09"></a>A09 | Year 1 average logistics fee per pickup mission | 2,800 DZD | Baseline pickup fee for route execution and handling at pilot scale. |
| <a id="a10"></a>A10 | Year 1 alert handling fee for non-compliance events | 900 DZD/event | Cost recovery for exception workflow effort and escalation handling. |

## Demand, Capacity, and Growth Assumptions

| ID | Assumption | Base Value | Rationale |
|---|---|---:|---|
| <a id="a11"></a>A11 | Source-node annual growth rate (Y2 to Y5) | 35% | Aggressive but realistic with institutional partnerships. |
| <a id="a12"></a>A12 | Average missions per active source per year | 3.4 | Reflects repeated pickups during seasonal cycles. |
| <a id="a13"></a>A13 | Fraction of missions producing discrepancy alerts | 14% in Y1, down to 8% by Y5 | Better process discipline should reduce avoidable mismatches. |
| <a id="a14"></a>A14 | Collection-stage QR tagging adoption | 100% from go-live | Mandatory for chain continuity and batch identity. |
| <a id="a15"></a>A15 | Depot-to-wash handover digital confirmation rate | 97% in Y1, 99% by Y3 | Minor operational slippage expected early, then standardization. |
| <a id="a16"></a>A16 | Offline data-capture dependency in field missions | 45% of missions in Y1 | Connectivity variability in rural/remote collection areas. |
| <a id="a17"></a>A17 | Offline queue replay success within 24h | 94% in Y1, 98% by Y3 | Reliability target for sync architecture hardening. |
| <a id="a18"></a>A18 | Average transformation lot size | 380 kg input equivalent | Supports planning of downstream D3/D4 throughput. |
| <a id="a19"></a>A19 | Output split after transformation | 62% D3, 38% D4 | Initial product mix assumption for commercialization planning. |
| <a id="a20"></a>A20 | Contracted buyer retention (annual) | 82% in Y1, 89% by Y5 | Improved transparency expected to increase buyer confidence. |

## Cost and Operating Assumptions

| ID | Assumption | Base Value | Rationale |
|---|---|---:|---|
| <a id="a21"></a>A21 | Field operations fixed cost (Year 1) | 18.6M DZD | Team, vehicles, supervision, and dispatch overhead. |
| <a id="a22"></a>A22 | Platform engineering and cloud cost (Year 1) | 12.4M DZD | Mobile, backend, dashboard, storage, and observability stack. |
| <a id="a23"></a>A23 | Compliance, audit, and governance cost (Year 1) | 3.2M DZD | Data protection controls, policy work, and audit process. |
| <a id="a24"></a>A24 | Training and change-management cost (Year 1) | 2.7M DZD | SOP rollout across collectors, depot, wash, and transform teams. |
| <a id="a25"></a>A25 | Variable logistics cost per mission (Year 1) | 690 DZD | Fuel, loading/unloading, and consumables per trip. |
| <a id="a26"></a>A26 | Variable processing support cost per processed kg | 27 DZD/kg | Labels, QA effort, and digital processing overhead. |
| <a id="a27"></a>A27 | Annual inflation pass-through on operating costs | +4.0% | Aligned with national inflation context. |
| <a id="a28"></a>A28 | Annual fee escalation on service pricing | +3.0% | Slightly below inflation to preserve adoption momentum. |
| <a id="a29"></a>A29 | R&D and contingency reserve | 6% of annual operating cost | Protects delivery against technical and operational surprises. |
| <a id="a30"></a>A30 | Depreciation proxy for equipment and infrastructure | 8% of relevant capex envelope | Simplified planning proxy for estimate-level modeling. |

## Financial and Scenario Rules

| ID | Assumption | Base Value | Rationale |
|---|---|---:|---|
| <a id="a31"></a>A31 | Working-capital buffer | 4 months of average operating cost | Guards against seasonality and payment delays. |
| <a id="a32"></a>A32 | Revenue recognition delay for institutional contracts | 45 days average | Reflects common enterprise billing cycles. |
| <a id="a33"></a>A33 | Conservative scenario revenue multiplier | 0.82x base | Lower adoption + slower route utilization. |
| <a id="a34"></a>A34 | Conservative scenario cost multiplier | 1.09x base | Lower efficiency with relatively fixed field overhead. |
| <a id="a35"></a>A35 | Upside scenario revenue multiplier | 1.18x base | Faster onboarding and stronger commercial throughput. |
| <a id="a36"></a>A36 | Upside scenario cost multiplier | 1.04x base | Scale gains partially offset by growth complexity. |
| <a id="a37"></a>A37 | Break-even KPI definition | Annual operating profit >= 0 | Standard operating break-even threshold. |
| <a id="a38"></a>A38 | Minimum target gross margin by Year 5 | 31% | Indicates healthy service economics at scale. |
| <a id="a39"></a>A39 | Risk reserve trigger | Alert rate > 16% for 2 consecutive quarters | Requires process correction budget release. |
| <a id="a40"></a>A40 | Year 5 transformation traceability coverage | >= 96% lots with complete stage linkage | End-state chain visibility objective. |

## Derived Formula Notes

- Processed gross volume per year = `active sources x avg declared volume x realization ratio` [A02], [A03], [A04].
- Net washed equivalent = `processed gross x (1 - D0/D1 loss) x (1 - D1/D2 loss)` [A05], [A06].
- Service revenue base = `(processed gross x per-kg fee) + (missions x logistics fee) + (alerts x handling fee)` [A08], [A09], [A10], [A12], [A13].
- Scenario outputs apply multipliers in [A33]-[A36].
