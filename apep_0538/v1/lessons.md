## Discovery
- **Policy chosen:** France's ZFE (low-emission zones) — staggered adoption across 11 cities (2016-2024), universe DVF transaction data, distributional angle on environmental policy costs
- **Ideas rejected:** Russia gas cutoff (endogenous exposure, crowded literature), Fiber broadband & populism (saturated topic, weak identification via density thresholds)
- **Data source:** DVF bulk CSV (cadastre.data.gouv.fr) + BNZFE boundary GeoJSON (transport.data.gouv.fr) + Open-Meteo air quality API
- **Key risk:** ZFE boundaries are not random — they follow city center perimeters with different secular trends. Mitigation: narrow boundary bandwidth, repeat-sales, strong placebos

## Execution
- **Key finding:** TWFE shows +22% but CS-DiD shows -0.3% (null). Pre-trends in event study confirm TWFE is biased.
- **Data issues:** Geo-DVF only covers 2020-2024 (not 2014+). CEREMA API too slow for commune pre-trends. ZFE boundary URLs needed data.gouv.fr API to find correct download link.
- **Methodological lesson:** Boundary DiD fails when boundary correlates with urban-suburban divide. CS-DiD essential for honest estimation with staggered adoption.
- **Paper rewrite:** Originally framed as positive capitalization + regressive incidence. Honest results required complete rewrite as null result paper — much stronger contribution.
- **Technical:** 8GB RAM requires chunked spatial processing (100K points per chunk). data.table + sf + fixest work well for this scale.

## Review
- **Advisor verdict:** 3 of 4 PASS (round 6 — took 6 rounds due to city count inconsistencies, CS-DiD design description, and always-treated cities)
- **Top criticism:** CS-DiD uses outside-boundary communes as "never-treated" controls, but paper argues those same units have different trends from inside-boundary ones. Tension resolved by explicitly stating the identifying assumption (inside-boundary trends parallel across cities) and showing CS-DiD dynamic effects support it.
- **Surprise feedback:** Reviewers flagged that air quality first stage lacked month-of-year FE for seasonality — obvious in hindsight. Added and PM2.5 result became borderline (p=0.056 vs p<0.001 before).
- **What changed:** (1) Excluded Paris/Grenoble from CS-DiD explicitly, (2) added CS-DiD leave-one-city-out robustness, (3) fixed air quality FE structure, (4) softened "precisely estimated null" to "rules out large effects," (5) clarified CS-DiD estimand and identifying assumption throughout.

## Summary
- **Total advisor rounds:** 6 (primarily internal consistency issues with city counts, CS-DiD description, and always-treated handling)
- **Key lesson for future:** When writing boundary DiD papers, be extremely precise about: (a) which cities are in which sample at which stage, (b) how the CS-DiD treatment/control assignment works at the unit level, (c) how always-treated units are handled. These details are easy to get inconsistent when the paper evolves.
- **The null result is the contribution:** The TWFE-vs-CS-DiD divergence (+22% vs -0.3%) is the paper's main finding. Null results with strong identification are valuable.
