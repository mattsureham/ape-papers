## Discovery
- **Idea selected:** idea_1642 — FOBT stake reduction and crime, chosen for mechanism decomposition potential (financial strain vs foot traffic)
- **Data source:** Home Office Police Recorded Crime open data tables (PFA-level), NOMIS UK Business Counts
- **Key risk:** COVID confound (only 11 months between treatment and lockdown), pre-trend failure in naive DiD

## Execution
- **What worked:** Triple-difference design (acquisitive vs non-acquisitive crime × betting density × post) cleanly absorbs the urban trend confound that contaminated the baseline DiD. Food service density control also helped isolate gambling-specific effects.
- **What didn't:** ONS API/website downloads — rate limiting and unknown URLs. Had to pivot to Home Office published tables on gov.uk. Also, LA-to-PFA name matching was imperfect (92 of 406 unmatched).
- **Review feedback adopted:** TBD — reviews pending
