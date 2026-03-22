## Discovery
- **Idea selected:** idea_1729 — SNAP stocking requirements and food retail access, using continuous-treatment DiD
- **Data source:** Census CBP (via Census API), ACS 5-year (via tidycensus). USDA RUCC download failed, derived rural from population.
- **Key risk:** Pre-reform convenience store share as treatment intensity might be endogenous to county economic trajectories

## Execution
- **What worked:** CBP data fetched cleanly for 12 years × 2 NAICS codes = 24 API calls. Panel construction straightforward. Event study cleanly revealed pre-trend violations.
- **What didn't:** The continuous-treatment DiD fundamentally failed — pre-reform industry composition is correlated with county-level trends. The placebo test at 2014 was devastating (β = 0.54, p < 0.001). The supermarket "placebo" also failed (significant negative), indicating the treatment variable proxies county economics, not stocking rule exposure.
- **Key lesson:** Continuous-treatment DiD designs using pre-reform industry composition as treatment intensity are deeply vulnerable to pre-existing divergence. Pre-trend testing is essential, not optional. The state×year FE specification rescued credibility but at the cost of power.
- **Review feedback adopted:** Added MDE/power discussion, improved measurement limitation framing, better distinguished store closure from SNAP deauthorization.

## Methodological Note
For future SNAP retailer research, the USDA SNAP Retailer Historical Database (with individual authorization/end dates) is essential. CBP cannot distinguish SNAP deauthorization from store closure, and county-level aggregation masks tract-level food desert dynamics.
