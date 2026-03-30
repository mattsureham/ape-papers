## Discovery
- **Idea selected:** idea_1963 — ARCOS pill supply → IPEDS SA counseling completions (novel linkage)
- **Data source:** Azure (ARCOS 178M transactions, IPEDS DuckDB) — worked after fixing truncated connection string
- **Key risk:** Pill supply proxies for county size; identification is descriptive, not causal
- **First attempt failed:** idea_2149 (UK high-cost credit) — BoE IADB API entirely down, Bankstats only has 24 months

## Execution
- **What worked:** Azure data pipeline for both ARCOS and IPEDS; county name matching (50% rate); OLS/panel DiD/growth rate all significant
- **What didn't:** IV (triplicate states) imprecise (F=14.1, p=0.27); placebo outcomes also significant (county size confound); DDD on levels negative
- **Review feedback adopted:** Moderated causal language throughout; added explicit limitations paragraph; reframed as descriptive association; acknowledged placebo results honestly
