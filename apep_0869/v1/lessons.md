## Discovery
- **Idea selected:** idea_1661 — Rosenbach v. Six Flags / BIPA enforcement shock. Sharp court ruling, rich QCEW data, border-county design.
- **Data source:** BLS QCEW via API — industry-level endpoint works well for 2-digit NAICS; hyphenated codes (31-33) return 404.
- **Key risk:** Six state clusters for inference; WCB failed due to singleton FE removal.

## Execution
- **What worked:** Border-county triple-diff design was clean and produced a strong, clear result (-9.3% employment). The built-in placebo (exempt industries) is very convincing. Event study is textbook — flat pre-trend, sharp break, progressive widening.
- **What didn't:** Manufacturing (NAICS 31-33) unavailable from QCEW API — the hyphenated code format isn't supported. County adjacency file from Census returned garbage (just "NA"). Had to hardcode border county FIPS.
- **Surprising finding:** Establishments INCREASED while employment fell — the compositional shift toward smaller firms is the real economic discovery, not just the employment decline.
- **Review feedback adopted:** Strengthened GLBA/HIPAA preemption discussion, expanded pre-COVID subsample interpretation with quarterly event-study coefficients, acknowledged six-cluster limitation more explicitly.
