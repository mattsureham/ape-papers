## Discovery
- **Idea selected:** idea_1075 — Secure Communities enforcement tax (industry reallocation of Hispanic workers)
- **Data source:** Census QWI from Azure (9.6M rows, 51 states) + ICE FOIA activation dates (3,071 counties)
- **Key risk:** Great Recession coinciding with early SC rollout; mitigated by triple-diff and late-activator robustness

## Execution
- **What worked:** QWI ethnicity × NAICS-3 data is ideal for this question; built-in non-Hispanic placebo is clean; C-S estimator with 2,600+ treated counties gives excellent power
- **What didn't:** Azure DuckDB connection failed with `sprintf` (Base64 `+`/`=` characters mangled); ICE Excel had non-standard headers requiring skip + manual date conversion from Excel serial numbers
- **Review feedback adopted:** Code advisor suggested deeper engagement with the triple-diff marginal significance and more explicit power analysis — addressed in the discussion section framing
- **Key lesson:** When connecting to Azure via DuckDB in R, use `paste0()` not `sprintf()` to construct the SQL secret creation command — the connection string contains characters that confuse format specifiers
