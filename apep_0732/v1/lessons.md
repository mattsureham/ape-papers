## Discovery
- **Idea selected:** idea_1658 — Time zone boundary × heat mortality interaction. Chosen for sharp geographic discontinuity, vivid mechanism, and built-in winter placebo. The "Does the clock kill?" hook was compelling.
- **Data source:** NOAA nClimDiv (temperature, 1999-2023) + County Health Rankings (mortality, 2019-2024) + ACS (demographics). CDC WONDER county-level mortality was inaccessible via API — required interactive form-based queries.
- **Key risk:** YPLL outcome misses deaths among 75+, the most heat-vulnerable population. Reviewers correctly flagged this.

## Execution
- **What worked:** Clean RDD design — McCrary passes (p=0.39), all covariates smooth at boundary. The null result is decisive and holds across all specifications.
- **What didn't:** CDC WONDER data inaccessibility forced pivot to CHR, which uses rolling 3-year mortality windows. This severely limits panel identification — all three reviewers flagged the temporal alignment issue. The panel FE specification (Column 5) produced a significant negative interaction that contradicts the cross-sectional null and raised reviewer suspicion of misspecification.
- **Review feedback adopted:** (1) Added explicit YPLL age-75 limitation discussion, (2) Reframed Column 5 panel result with appropriate caveats about temporal alignment, (3) Added MDE/power discussion, (4) Clarified running variable definition with exact boundary longitudes.
- **Key lesson for future:** County-level mortality data is surprisingly hard to get programmatically in the US. CDC WONDER is the gold standard but requires interactive agreement-based access. For future heat mortality papers, either budget time for manual CDC WONDER queries or use the CDC restricted-use county mortality files. YPLL is a reasonable alternative but mechanically misses the 75+ population.
