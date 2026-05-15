# YallaRent Assumptions Register

This file stores internal modeling assumptions used in all strategic documents. Every projected number in the plan links back to one or more assumptions below.

## External Baseline Assumptions

| ID | Assumption | Value | Basis |
|---|---|---|---|
| <a id="a01"></a>A01 | Planning horizon | 5 academic years starting AY 2026/2027 | User-locked scope |
| <a id="a02"></a>A02 | Core addressable university population (TAM baseline) | 1,530,230 enrolled students | MESRS 2024/2025 [S09](./sources.md#s09) |
| <a id="a03"></a>A03 | Macro inflation reference for cost escalation | 4.046% annual CPI | World Bank [S07](./sources.md#s07) |
| <a id="a04"></a>A04 | Youth affordability pressure remains high | Youth unemployment 29.444% | World Bank [S06](./sources.md#s06) |
| <a id="a05"></a>A05 | Digital channel readiness | 76.9% internet penetration, 54.8M mobile connections | DataReportal [S15](./sources.md#s15), [S16](./sources.md#s16) |

## Demand, Supply, and Operating Assumptions (Base Case)

| ID | Assumption | AY26/27 | AY27/28 | AY28/29 | AY29/30 | AY30/31 |
|---|---|---:|---:|---:|---:|---:|
| <a id="a06"></a>A06 | Campuses served | 1 | 3 | 7 | 12 | 18 |
| <a id="a07"></a>A07 | Active renter accounts | 1,200 | 3,800 | 10,500 | 25,000 | 47,500 |
| <a id="a08"></a>A08 | Company-owned rental orders | 7,200 | 18,000 | 36,000 | 60,000 | 90,000 |
| <a id="a09"></a>A09 | Average fee per company-owned order (DZD) | 1,800 | 1,900 | 2,000 | 2,100 | 2,200 |
| <a id="a10"></a>A10 | Delivery attach rate on total orders | 35% | 40% | 42% | 45% | 47% |
| <a id="a11"></a>A11 | Delivery fee per delivered order (DZD) | 300 | 320 | 340 | 360 | 380 |
| <a id="a12"></a>A12 | Damage-protection attach rate | 60% | 65% | 67% | 70% | 74% |
| <a id="a13"></a>A13 | Damage-protection fee per protected order (DZD) | 180 | 200 | 220 | 240 | 260 |
| <a id="a14"></a>A14 | Paying provider subscriptions (>3 listings, no commission model) | 150 | 500 | 1,400 | 2,800 | 4,500 |
| <a id="a15"></a>A15 | Annual provider plan price (DZD) | 12,000 | 12,000 | 12,000 | 12,000 | 12,000 |
| <a id="a16"></a>A16 | University partnership contracts (count) | 2 | 5 | 10 | 18 | 28 |
| <a id="a17"></a>A17 | Avg annual partnership fee (DZD) | 1,500,000 | 1,800,000 | 2,000,000 | 2,200,000 | 2,400,000 |
| <a id="a18"></a>A18 | Maintenance/repair service orders | 900 | 2,400 | 4,800 | 7,800 | 12,000 |
| <a id="a19"></a>A19 | Avg maintenance fee (DZD) | 600 | 650 | 700 | 750 | 800 |
| <a id="a20"></a>A20 | End-of-cycle resale units | 220 | 600 | 1,100 | 1,800 | 2,600 |
| <a id="a21"></a>A21 | Avg resale realization per unit (DZD) | 8,000 | 8,500 | 9,000 | 9,500 | 10,000 |

## Risk and Sensitivity Assumptions

| ID | Assumption | Base Value | Use in Sensitivity |
|---|---|---:|---|
| <a id="a22"></a>A22 | Inventory utilization rate | 58% monthly active utilization | Tested at 48%, 58%, 68% |
| <a id="a23"></a>A23 | Non-recoverable loss/damage rate | 2.8% of inventory value per year | Tested at 2.0%, 2.8%, 4.0% |
| <a id="a24"></a>A24 | Campus acquisition pace | 1 -> 3 -> 7 -> 12 -> 18 | Tested with +/- 1 campus each year from Y2 onward |

## Financial and Scenario Rules

| ID | Assumption | Rule |
|---|---|---|
| <a id="a25"></a>A25 | Revenue scenario multipliers | Conservative = 0.80x base revenue; Upside = 1.25x base revenue |
| <a id="a26"></a>A26 | Cost scenario multipliers | Conservative = 0.92x base opex/cogs; Upside = 1.10x base opex/cogs |
| <a id="a27"></a>A27 | Break-even definition | First year where total revenue >= total operating costs and yearly cash flow is positive |
| <a id="a28"></a>A28 | No commission policy on peer-to-peer rentals | Platform monetizes P2P via subscription plans, protection, and logistics, not transaction commission |
| <a id="a29"></a>A29 | Currency policy | All financial tables are in DZD only |
| <a id="a30"></a>A30 | Proxy rule for data gaps | If Algeria metric missing, use transparent proxy and explicit conversion note with link |

## Derived Metrics Formula References

- <a id="a31"></a>A31 `Company-owned rental revenue = A08 x A09`
- <a id="a32"></a>A32 `Delivery revenue = Delivered orders x A11` where delivered orders follow A10 attach rates.
- <a id="a33"></a>A33 `Protection revenue = Protected orders x A13` where protected orders follow A12 attach rates.
- <a id="a34"></a>A34 `Subscription revenue = A14 x A15`
- <a id="a35"></a>A35 `Partnership revenue = A16 x A17`
- <a id="a36"></a>A36 `Maintenance revenue = A18 x A19`
- <a id="a37"></a>A37 `Resale revenue = A20 x A21`

