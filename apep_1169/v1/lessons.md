## Discovery
- **Idea selected:** idea_1669 — One-stop business registration portals and firm formation (US staggered DiD)
- **First attempt failed:** idea_2106 (Taiwan conscription → marriage RDD) failed because Taiwan's open data only provides 5-year age groups for marital status nationally. Single-year resolution needed for RDD unavailable.
- **Data source:** Census BFS via FRED API — weekly windowed series `BUSAPPWNSA{ST}`. Series IDs were non-obvious; had to discover via search. Some transient 500 errors on FRED API.
- **Key risk:** Only 11 treated states. Tournament penalizes small N. Mitigated by monthly frequency (12K+ obs) and precise estimates.

## Execution
- **What worked:** FRED API pipeline reliable after discovering correct series IDs. CS DiD ran cleanly on balanced panel. Bacon decomposition confirmed 90% clean comparison weight.
- **What didn't:** Initial Taiwan idea wasted ~15 minutes on data exploration before discovering granularity limitation. Should have verified data resolution earlier.
- **Review feedback adopted:** Expanded limitations section with portal scope heterogeneity, distance-to-capital hypothesis, power limitations for subgroup analysis.
