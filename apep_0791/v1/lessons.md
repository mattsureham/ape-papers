## Discovery
- **Idea selected:** idea_1472 — GE Rule on/off cycle with racial credential attainment. Strong policy relevance and data availability.
- **Data source:** IPEDS DuckDB on Azure (1.2 GB) — DuckDB ATTACH failed with Azure extension v1.4.4; had to download via Python azure-storage-blob SDK.
- **Key risk:** Pre-existing trends from Great Recession confounding the DD estimate. Confirmed.

## Execution
- **What worked:** The DDD race-stacked panel design with institution × race, race × year, and institution × year FE worked cleanly. The event study clearly showed the pre-trend contamination, making the narrative compelling.
- **What didn't:** `fixest::i(binary_var, continuous_var)` creates collinearity with unitid FE — must use plain `forprofit:ge_active` interaction syntax. Also, the full-sample DD gives a misleading positive result that requires careful decomposition.
- **Review feedback adopted:** Added formal F-test for 2011-2013 pre-trends (F=3.48, p=0.015), lagged treatment specifications (1-year and 2-year), and clarified enforcement reality (no programs lost Title IV). Reviewers uniformly wanted program-level GE intensity from College Scorecard — infeasible for V1 but strong improvement opportunity.
