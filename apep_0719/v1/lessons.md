## Discovery
- **Idea selected:** idea_0277 — Alien Land Laws and Japanese occupational sorting. Chose for vivid human story, clean identification, and individual-level linked data.
- **Data source:** IPUMS MLP linked panels on Azure (4.9 GB parquet). Downloaded via DuckDB in ~8 minutes.
- **Key risk:** Few treated clusters (7 states) limits inference precision.

## Execution
- **What worked:** The DDD design (Japanese × Treated with white placebo) is the paper's strongest feature. White farmers showing the OPPOSITE pattern (lower farm exit in treated states) is an unusually clean falsification. The 1920-1940 persistence result (t=2.49) distinguishes this from temporary displacement.
- **What didn't:** State FE collinear with treatment in within-race models — had to use simple OLS with clustered SEs for Japanese-only specs. The farm owner vs laborer heterogeneity was unexpected (owners don't respond) but has a clean explanation (legal circumvention through citizen children).
- **Review feedback adopted:** Added pre-trends limitation discussion, few-clusters caveat, wealth vs prestige distinction in Discussion. All three reviewers flagged the same core issues.
