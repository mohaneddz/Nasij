# Nasij Glossary

- **Batch / Lot**: A uniquely identified wool unit that is tracked across every stage of the chain.
- **C1 / C2 / C3**: Source actor categories in Nasij workflows (farmer, butcher/slaughter source, third party source).
- **Collector**: Field operator who executes pickup missions and records initial lot metadata.
- **D0 / D1 / D2**: Processing checkpoints used in this estimate:
  - `D0`: declared/field-collected gross state
  - `D1`: depot-prepared state after initial sorting/cleaning
  - `D2`: washed state before transformation
- **D3 / D4**: Final commercial output classes after transformation.
- **Discrepancy Alert**: A rule-triggered exception when measured values diverge from expected ranges between stages.
- **Gross-to-Net Reduction**: Expected mass reduction between stages due to impurity removal and process loss.
- **Offline Outbox**: Local queue used when network is unavailable; operations replay when connectivity returns.
- **Realization Ratio**: Share of declared volume that is actually collected and entered into the process.
- **Traceability Coverage**: Share of lots with complete linked records from collection to commercialization.
- **Trust Score**: Internal reliability metric for operational actors based on behavior/events (e.g., cancellations, discrepancies).
- **Working Capital Buffer**: Liquidity reserve used to absorb seasonality, delayed payments, and shock periods.
