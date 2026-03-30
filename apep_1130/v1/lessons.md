## Discovery
- **Idea selected:** idea_1927 — SBA size standard increases and geographic procurement redistribution. Novel angle on firm-level displacement work by Denes et al. (2024).
- **Data source:** USAspending API (county-level procurement by NAICS sector and FY). RUCC download failed (USDA changed URL); used Census ACS population for metro classification instead.
- **Key risk:** Sector-level aggregation (19 sectors) limits power and variation vs. the original manifest's 200+ NAICS codes.

## Execution
- **What worked:** The "crowding-out gradient" framing — naming the mechanism gave the paper a clear identity. USAspending API was reliable (only 1 of 494 calls failed). The county count result (−85 counties, p<0.01) is the strongest finding.
- **What didn't:** Aggregation to 2-digit NAICS was necessary for API feasibility but costly for identification. The placebo on total procurement (significant decline) raises confounding concerns that the paper acknowledges but cannot fully resolve.
- **Review feedback adopted:** Strengthened limitations section to acknowledge aggregation trade-off, added pre-trend coefficient values, and expanded placebo discussion. Reviewers unanimously recommended moving to 6-digit NAICS county panel in revision.
