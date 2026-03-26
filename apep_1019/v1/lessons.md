## Discovery
- **Idea selected:** idea_0152 — Old-age pensions and occupational mobility (MLP linked census data)
- **Data source:** Azure MLP panel (derived/mlp_panel/linked_1920_1930_1940.parquet) — 34.7M rows, confirmed and accessible
- **Key risk:** Pre-trends from endogenous policy adoption; 3-period panel limits event study diagnostics

## Execution
- **What worked:** Azure data pipeline smooth; 6.94M men linked across 3 censuses; fixest handled 20.8M rows efficiently; Sun-Abraham decomposition ran without issues
- **What didn't:** R DuckDB Azure extension broken (Python DuckDB works); model objects too large to save/load (2.2GB RDS file); memory pressure from multiple regressions required careful gc() management
- **Surprise finding:** Main hypothesis FAILED — no occupational upgrading from pensions. Farm residence increased (opposite of prediction). Pre-trends significant for occscore. Reframed paper around the null.
- **Review feedback adopted:** All 3 reviewers flagged pre-trends → added early-adopter-only analysis showing positive (but imprecise) effect in clean 1920-1930 window; incorporated Depression/SSA contamination discussion; added nuanced interpretation that pooled null masks heterogeneity across treatment cohorts
