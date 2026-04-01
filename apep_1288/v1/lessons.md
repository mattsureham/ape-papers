## Discovery
- **Idea selected:** idea_1846 — Child labor law relaxations (2022-2023), picked for novelty (no published study), clean data path (QWI on Azure), and first-order policy stakes
- **Data source:** QWI via Azure DuckDB — worked flawlessly, 105K rows in seconds. Connection string truncation issue required manual parsing from .env
- **Key risk:** Small number of treated states (6); addressed with DDD (within-state adult control), leave-one-out, and MDE analysis

## Execution
- **What worked:** Azure QWI data access was the fastest data fetch in any APEP paper. The DDD design naturally addresses the small-N concern by leveraging within-state age variation. The null result is clean and tells a sharp story.
- **What didn't:** Wild cluster bootstrap failed due to fixest's `^` FE notation incompatibility with fwildclusterboot. CS estimator flagged "small groups" and lacked a proper never-treated identifier (needed Inf, not 0). Event study required careful handling of never-treated relative time assignment.
- **Review feedback adopted:** Added MDE/power discussion for null interpretation. Fixed misleading teen employment share description (clarified as A01/(A01+A03), not teens/all workers). Acknowledged log(Y+1) vs log(Y) equivalence at state level. Fixed text-table mismatches in event study coefficients.
