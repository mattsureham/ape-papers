## Discovery
- **Idea selected:** idea_1849 — SDLT bunching migration from April 2025 threshold reversion
- **Data source:** HM Land Registry Price Paid Data — 1.56M transactions, clean bulk CSV download
- **Key risk:** Kinks (vs notches) produce small behavioral responses; round-number bunching dominates

## Execution
- **What worked:** The round-number-adjusted ratio approach cleanly separates SDLT-specific bunching from pervasive £5K price clustering. The £250K result (t = -2.34) is robust across all specifications.
- **What didn't:** Standard polynomial counterfactual (Chetty/Kleven) fails in housing markets due to round-number bunching. SEs from polynomial approach were 2-4x the point estimates. Had to pivot methodology entirely.
- **Review feedback adopted:** [pending — reviews in progress]

## Key Insight
Housing markets require purpose-built bunching estimators that account for discrete pricing norms. The standard approach designed for income tax data does not transfer directly. The round-number-adjusted ratio is a simple, interpretable alternative.
