## Discovery
- **Idea selected:** idea_0291 — Municipal broadband preemption → COVID telehealth divide. Chose for clean predetermined treatment (22 states, 1997-2019), confirmed CMS data, and first-order health stakes.
- **Data source:** CMS Medicare Telehealth Trends (33,712 rows via Data API v2), ACS B28002/B19013/B15003, hand-coded preemption laws from ILSR
- **Key risk:** Only 1 pre-COVID quarter in CMS data; mechanism test depends on broadband channel that's hard to measure at state level

## Execution
- **What worked:** CMS Data API v2 with pagination; ACS tidycensus; the "restriction trap" framing; event study showing peak at 2020Q2 then convergence
- **What didn't:** Triple-diff rural interaction was null (-0.18pp, p=0.72), undermining the rural broadband story. Had to reframe as statewide market structure effect. Pre-COVID broadband gap only 0.5pp (not significant).
- **Review feedback adopted:** Added ACS broadband pre-trend analysis (2015-2019); acknowledged staggered treatment limitation; added welfare back-of-envelope; strengthened null rural interpretation
