## Discovery
- **Idea selected:** idea_2210 — Undocumented racial earnings erosion in NAICS 624, testing Medicaid expansion as mechanism
- **Data source:** QWI rh/n3 from Azure (3.9M rows) — county-level suppression 59% for Black workers forced state-level aggregation
- **Key risk:** QWI earnings are monthly averages conflating wages and hours; minimum wage confounding

## Execution
- **What worked:** CS estimator cleanly identified race-specific earnings effects; placebo sectors null
- **What didn't:** Triple-diff collinear with staggered FEs — replaced with race-decomposed CS. Found critical aggregation bug in dplyr summarise (sequential evaluation overwrites column names)
- **Review feedback adopted:** Added minimum wage confounding discussion, Great Recession context for erosion trough, acknowledged subsector decomposition limitation (4-digit suppression prevents it)
- **Key finding:** Medicaid expansion raised Black earnings 3.6% and White earnings 1.8%, but ratio effect (1.5 pp) is imprecise — honest null on convergence
