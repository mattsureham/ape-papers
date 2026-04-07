## Discovery
- **Idea selected:** idea_2539 — Colombia PNIS voluntary coca substitution, largest voluntary program ever, clean data from datos.gov.co
- **Data source:** datos.gov.co — SIMCI coca panel (319 munis × 23 years), PNIS enrollment (56 munis), eradication events (145K)
- **Key risk:** Pre-trends from "peace dividend" coca boom in PNIS-eligible areas

## Execution
- **What worked:** datos.gov.co API was fast and reliable. Municipality-year panel construction was clean. Sun-Abraham + TWFE + Callaway-Sant'Anna convergence built confidence in the null.
- **What didn't:** Callaway-Sant'Anna estimator had issues with never-treated group encoding (dropped 264 municipalities). Wave assignment was approximate (department-level, not municipality-level dates).
- **Review feedback adopted:** Municipality-specific linear time trends revealed marginally significant effect (-0.61, p=0.06) — the pre-trend was masking genuine but modest compliance. Added scope acknowledgment about labor market outcomes from ENA being out of reach.
- **Key insight:** The "substitution mirage" concept — compliance during payment windows followed by reversion — is the contribution. The muni-specific trend finding strengthens the nuance: PNIS had a real but fragile effect that the peace-dividend pre-trend obscured.
