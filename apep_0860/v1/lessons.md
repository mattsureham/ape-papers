## Discovery
- **Idea selected:** idea_1695 — Catalytic converter anti-theft laws and scrap metal markets
- **Data source:** Census CBP API (NAICS 423930) — reliable and immediate; Yahoo Finance for palladium prices
- **Key risk:** FBI NIBRS data was inaccessible (API deprecated, ICPSR requires auth). Pivoted from crime outcome to market structure outcome.

## Execution
- **What worked:** The data pivot from NIBRS crime data to CBP establishment counts turned out to be a more novel angle. "Did laws squeeze the market?" is more interesting than "did laws reduce theft?" because it tests a specific mechanism (compliance cost absorption vs. market exit).
- **What didn't:** The palladium price decomposition is underpowered — pd_std is collinear with year FE (varies only by year), so the interaction term captures limited variation. A triple-difference design would be stronger.
- **Review feedback adopted:** Reframed contribution around compliance-cost absorption rather than crime deterrence. Added explicit acknowledgment that the paper cannot test theft reduction. Strengthened discussion of informal sector limitation and the "what this paper cannot identify" section. Improved interpretation of positive t+2 coefficient as potential "formalization dividend."
- **Null result strategy:** The null is well-powered (can rule out >4% declines in establishments) and robust across all specifications. Framed assertively as informative constraint on the compliance-cost channel, not as a failure to find effects.
