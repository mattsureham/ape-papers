## Discovery
- **Idea selected:** idea_1857 — Craft brewery self-distribution laws and manufacturing employment
- **Data source:** QWI on Azure (NAICS 312/311) — pre-processed Parquet files, immediate access, no API issues
- **Key risk:** NAICS 312 too broad (includes soft drinks, tobacco); 30% craft brewery share dilutes signal

## Execution
- **What worked:** State-quarter panel construction from Azure QWI was fast and clean. Triple-difference against NAICS 311 (food manufacturing) provided the most compelling falsification — identical coefficients (-0.081) in both industries. CS-DiD with not-yet-treated controls gave a positive point estimate that flipped the TWFE sign, illustrating the forbidden-comparison bias clearly.
- **What didn't:** Earnings variable had 98% NAs at state-quarter level (QWI suppression), making earnings analysis impossible. Always-treated states coded as controls is a valid concern; a cleaner control group would require better data on pre-2001 self-distribution status.
- **Review feedback adopted:** Added county entry results and CS-DiD event study dynamics to the Results section. Reviewers wanted county-level regressions but the extensive margin showed no differential effect either.
