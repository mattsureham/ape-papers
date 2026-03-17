## Discovery
- **Idea selected:** idea_1414 — Automatic marijuana expungement × Black labor market outcomes; compelling because it separates expungement from legalization using QWI race panel
- **Data source:** Azure Blob `az://derived/qwi/rh/ns/*.parquet` — 132K rows, 1,537 counties, 19 states confirmed available
- **Key risk:** Small N (9 states) means cluster-robust SEs may be imprecise; DDD identification requires careful FE structure

## Execution
- **What worked:** QWI race panel via DuckDB-Arrow was fast and complete. Fixest TWFE ran cleanly. Main earnings finding (6.8%, p<0.001) is robust across 4 robustness specs.
- **What didn't:** (1) `cohort_expunge` scale mismatch — used `expunge_year * 4` not `(expunge_year - 2013) * 4`; applied in two places. (2) DDD stacked panel hit persistent collinearity; resolved by Wald test. (3) `models.rds` clobbered by `c(models, ...)` with undefined variable. (4) `se()` namespace conflict — always use `fixest::se()` explicitly. (5) Stars `^{***}` need math mode — wrap with `$^{***}$`.
- **Review feedback adopted:** Added DDD Wald test row to Table 2, formal triple-diff equation (2), between-group parallel trends note, CS-DiD robustness mention, small-cluster inference caveat, JEL K14 replacing I28.

## Key lesson
When running multiple sections of a script sequentially, never `c(variable, ...)` if that variable isn't in scope — always reload from RDS first. The `se()` function from fixest can be shadowed by dplyr/other packages; use explicit `fixest::se()`. DDD via stacked long format hits collinearity with the standard FE structure we use; Wald test is cleaner for 9 states.
