## Discovery
- **Idea selected:** idea_0781 — Becker discrimination channel via minimum wage using QWI race/ethnicity data. Chosen for novel angle (racial hiring flows) on well-studied policy (MW), winner data source (QWI), and strong design (30+ treated states, CS DiD).
- **Data source:** Census QWI API (race/ethnicity endpoint) — Azure connection failed; API requires year+quarter params and single race codes per call. 2,450 calls for full dataset.
- **Key risk:** Whether the Becker prediction would hold in hiring flows (it partially didn't — the null is the contribution).

## Execution
- **What worked:** CS DiD with 28 treated and 21 never-treated states, 71,280 county-year observations. The triple-difference and placebo sector tests worked cleanly. The discovery that Black separation rates increase significantly was an unexpected and interesting finding.
- **What didn't:** Azure DuckDB failed (URL format error despite correct secret), requiring fallback to Census API. The API's 500 error without year/quarter params cost 30 minutes of debugging. The simple Becker prediction was rejected on the hiring margin.
- **Review feedback adopted:** (1) Acknowledged dynamic positive effects at event years +2 to +4 that the overall ATT averages away. (2) Added discussion of border-county design omission and why. (3) Clarified QWI data access via public API for replicability. (4) Strengthened separation mechanism discussion with three candidate interpretations.
