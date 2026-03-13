## Discovery
- **Idea selected:** idea_0129 — Data breach notification laws and firm dynamics
- **Data source:** Census Bureau BDS via API — reliable, complete coverage (1998-2022)
- **Key risk:** All 50 states eventually treated, so no pure never-treated controls

## Execution
- **What worked:** Census BDS API was fast and reliable. 1,275 state-years with 51 states provides excellent power. Industry decomposition at NAICS level provides built-in mechanism test. Pre-trends are clean (all coefficients < 0.12pp).
- **What didn't:** Small cohorts (2003=1 state, 2011=1, 2014=1, 2017=1, 2018=2) generate warnings in CS estimator and collinearity in Sun-Abraham. Industry-level estimates are imprecise due to smaller within-sector samples.
- **Data engineering notes:** Census BDS API works at state-year-NAICS level. Must loop per year for aggregate data. NAICS sector codes use strings (e.g., "31-33" for Manufacturing). All rates are pre-computed by Census.
- **Key finding:** Well-powered null — BNLs had no effect on firm entry (+0.17pp, SE=0.16). Overturns the "compliance tax" narrative.
