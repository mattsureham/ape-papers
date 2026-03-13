## Discovery
- **Idea selected:** idea_0128 — Clean slate laws and statistical discrimination. Strong framing: tests whether permanent info destruction backfires like BTB.
- **Data source:** FRED API for BLS LAUS (unemployment rates, nonfarm employment), Census ACS API for race-stratified E-pop ratios.
- **Key risk:** Only 12 treated states — borderline for state-level DiD power. CS-DiD estimates are imprecise as a result.

## Execution
- **What worked:** The racial employment gap finding (1.3 pp narrowing, driven by Black employment gains) is compelling and contradicts the Doleac-Hansen prediction. Clean narrative arc from theory to results.
- **What didn't:** BLS API daily rate limit hit (25 requests/day without key). Had to switch to FRED API mid-pipeline. QWI data fetching was too slow for individual-state API calls — dropped QWI from V1 scope.
- **Data lesson:** Always use FRED as primary for BLS data — no daily rate limit. Reserve direct BLS API for specific series.
- **Review feedback adopted:** Strengthened event study description (now reports pre-period coefficients explicitly), expanded discussion of enactment-vs-implementation timing gap, better reconciled unemployment and employment findings.
- **Review feedback deferred to V2:** QWI hires/earnings decomposition, CPS ASEC race-age-education heterogeneity, formal mechanism tests (industry-level, dose-response by scope), event study figures.
