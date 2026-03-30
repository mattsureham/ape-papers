## Discovery
- **Idea selected:** idea_1801 — Cage-free egg mandates, staggered across 10 US states (2022-2026), with strong USDA NASS data and clear identification
- **Data source:** USDA NASS QuickStats API (layers + production) and BLS average prices — API required separate queries for EGGS and CHICKENS commodities; CHICKENS commodity too large for single fetch, needs specific short_desc filters
- **Key risk:** Only 6 of 9 treated states report monthly to NASS (MA, NV, AZ excluded); avian influenza timing overlap with CA mandate

## Execution
- **What worked:** Clean staggered DiD design, strong effects (CA -50%), clear placebo (eggs per 100 null), Bacon decomposition confirms 94% clean weight
- **What didn't:** Small treated sample (6 states) limits inference power; WCB p-values marginal (0.067); BLS price data only at regional level, no state-level price analysis possible
- **Review feedback adopted:** Added transport cost vs. cage-free premium calculation, strengthened spillover evidence with Iowa counter-trend, clarified HPAI regional pattern, made WCB p-values the primary inference basis, added caveat about event time +3 being CA-specific, noted NASS doesn't distinguish cage-free vs. conventional layers
