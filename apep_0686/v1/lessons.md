## Discovery
- **Idea selected:** idea_0982 — UK Housing Delivery Test RDD at the 75% threshold
- **Data source:** DLUHC HDT measurement files (ODS/XLSX) + PS2 planning statistics (CSV) — all publicly available, no API keys needed
- **Key risk:** Modest sample near cutoff (155 observations within ±10pp); imprecise nonparametric estimates

## Execution
- **What worked:** The institutional design is clean — sharp threshold, mechanically determined running variable, built-in placebo (householder applications). McCrary test passes cleanly. Covariate balance confirmed. The policy story writes itself: regulatory defaults matter.
- **What didn't:** HDT files had inconsistent formats across years (XLSX vs ODS, varying column positions). The 75% threshold was phased in (25% in 2018, 45% in 2019, 75% from 2020), which I didn't know until parsing the data. Had to restrict to 2020-2023 only.
- **Review feedback adopted:** (1) Clarified sign convention in results text — rdrobust reports μ+(c) - μ-(c), negative = treated have higher approval rates. (2) Rewrote abstract to be honest about imprecision — the nonparametric CI includes zero. (3) Added explicit explanation that 2020-2023 restriction is due to phased threshold introduction. (4) Clarified that the 75% comparison isolates presumption-plus-buffer vs buffer-only. (5) Added limitations paragraph on housing starts, figure constraints, and power.
