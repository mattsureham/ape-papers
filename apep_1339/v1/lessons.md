## Discovery
- **Idea selected:** idea_2299 — Dams designed with 1961-era precipitation estimates face larger floods; tests whether this "design gap" predicts flood damage
- **Data source:** NID (92K dams), FEMA OpenFEMA (11K flood declarations), NOAA nClimDiv (47K division-years) — all freely available APIs/downloads
- **Key risk:** Cross-sectional identification only (no clean temporal shock); precipitation changes might confound

## Execution
- **What worked:** NID is an excellent dataset — 73K CONUS dams with coordinates, year built, spillway capacity, hazard class. nClimDiv precipitation trends confirmed ~8% increase since design era.
- **What didn't:** TP-40 raster (1961 baseline precipitation) not accessible from Figshare. NFIP v1 API deprecated; had to use v2. County-level FIPS matching between NID (state names) and FEMA (FIPS codes) was painful — defaulted to state-level analysis.
- **Key finding:** Well-powered null. Dam vintage does NOT predict flood outcomes. States with more old dams have slightly FEWER declarations (Poisson β = −1.73, p = 0.048). Total storage matters, but composition between old and new does not.
- **Review feedback adopted:** All three reviewers identified state-level aggregation as the main weakness. Added explicit limitations paragraph acknowledging ecological fallacy, reframed null from "compensating mitigation" to three competing explanations (mitigation, aggregation bias, maintenance). Strengthened 1930s WPA/PWA cohort discussion. Fixed SDE table `\item` formatting.
