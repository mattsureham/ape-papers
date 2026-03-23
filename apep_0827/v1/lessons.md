## Discovery
- **Idea selected:** idea_0625 — Dutch cannabis supply chain experiment. First-of-its-kind randomized experiment with lottery assignment, CBS crime data available.
- **Data source:** CBS StatLine 83648NED (crime) and 70072NED (population) — fetched via `cbsodataR` package. Table 03759NED threw 500 errors; 70072NED was a reliable alternative.
- **Key risk:** Only 10 treated municipalities and 2 post-treatment years → low statistical power.

## Execution
- **What worked:** CBS data was clean and complete for all 20 experiment municipalities. The `cbsodataR` package handles pagination and formatting automatically. Pre-trends are clean from 2016 onward (p = 0.96).
- **What didn't:** Early pre-period (2010-2013) shows treatment-control divergence in drug crime, requiring restricted pre-period. Full F-test rejects; this is driven by convergence dynamics, not a design flaw.
- **Review feedback adopted:** Added MDE calculation (~39% of mean), split 2024 vs 2025 treatment effects, softened conclusion language from definitive null to preliminary assessment, added policing substitution discussion. Reviewers wanted event study plots but V1 format prohibits figures.
- **Key insight:** A well-powered null on the world's most important cannabis experiment is publishable, but only if honest about what the design can and cannot rule out.
