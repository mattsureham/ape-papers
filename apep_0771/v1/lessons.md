## Discovery
- **Idea selected:** idea_0326 — For-profit college closures and county labor markets. Chose this over fracking (known loser), India RTE (only 16 treated states), and Guatemala bunching (only 2 pre-periods).
- **Data source:** IPEDS (Azure DuckDB) + QWI (Azure Parquet). Both confirmed in Azure. Zero download risk.
- **Key risk:** Effect might be too small to detect at county-sector level because for-profits are a tiny share of NAICS 61.

## Execution
- **What worked:** Chain closures (ITT, Corinthian, ECA) provide clean quasi-exogenous variation. Large sample (864 counties, 12K+ county-year obs). IPEDS ATTACH to remote DuckDB worked but requires explicit `ATTACH` statement (can't use dot notation).
- **What didn't:** `did::att_gt()` threw "invalid first argument" even with explicit integer casting. Cause unknown — likely a data structure issue. Sun-Abraham via `fixest::sunab()` worked as drop-in replacement.
- **Key finding:** Hard null across all outcomes. SDEs < 0.005 for all six outcomes. For-profit closures are a non-event for county labor markets.
- **Review feedback adopted:** Added MDE discussion, softened policy conclusion, expanded pre-trends analysis, clarified control group definition. Reviewers unanimously flagged NAICS 61 aggregation issue (for-profits tiny within education sector) and chain IV timing simplification — left for V2.
