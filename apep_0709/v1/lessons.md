## Discovery
- **Idea selected:** idea_0030 — Burkina Faso conflict and food prices. Chose for clean staggered geography (violence diffusing from Mali) plus freely available market-level data (WFP + UCDP).
- **Data source:** WFP HDX (55K rows, 64 markets) + UCDP GED v24.1 (1,504 events). Both free CSV downloads, no authentication needed.
- **Key risk:** Small never-treated control group (only 4 of 64 markets). Mitigated by not-yet-treated controls in CS estimator.

## Execution
- **What worked:** Geographic matching (Haversine distance) produced clean treatment assignment. Pre-trends beautifully flat (joint p=0.45). The 30km radius result (6%, significant) is the paper's strongest finding. Commodity decomposition directionally supports mechanism.
- **What didn't:** Monthly CS estimation failed (unbalanced panel + 30 cohorts overwhelmed the estimator). Had to aggregate to quarterly. The main 50km ATT (2.2%) is imprecise (p=0.44). Only 5 of 12 WFP commodities matched to clean categories (no cowpeas). `data.table` `.BY` syntax doesn't carry non-grouping columns — had to switch to `lapply` loops for market-event distance matching.
- **Review feedback adopted:** Fixed Sun-Abraham NaN (was extracting wrong coefficient names). Corrected control group labels from "never-treated" to "not-yet-treated". Toned down mechanism claims — difference between cereal/rice coefficients not formally significant. Fixed observation counts in tables.
