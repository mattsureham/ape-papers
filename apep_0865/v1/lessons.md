## Discovery
- **Idea selected:** idea_1804 — Florida's quota liquor license lottery. Chosen for genuine randomization (lottery) + sharp institutional lever (7,500-person population threshold). Zero APEP overlap.
- **Data source:** BLS QCEW API (county-level drinking-place employment) + Census PEP API (population estimates). QCEW worked cleanly for 2014-2024; Census PEP endpoint for 2020+ returned 404s, limiting the panel to 2010-2019.
- **Key risk:** The treatment variable (license entitlements) is mechanically tied to population growth, creating confounding that the county + year FE cannot fully absorb.

## Execution
- **What worked:** The QCEW API delivered clean county-level data for NAICS 7224 (drinking places) and 7225 (restaurants). The treatment variable construction (floor division by 7,500) was straightforward. The wage compression finding (-$14/week, p=0.005) emerged as a genuine and novel result.
- **What didn't:** The RDD was underpowered with only 110 effective observations (MDE > 1,000 jobs). The restaurant placebo failed spectacularly (-751.6***), exposing population growth confounding in the baseline spec. The Census PEP 2020+ API was completely down.
- **Review feedback adopted:** (1) Reframed estimand as ITT on entitlement, not actual bar openings. (2) Acknowledged lottery-level data as the most promising future avenue. (3) Tempered policy conclusions to note that health benefits of quotas are a separate question. (4) Explicitly noted missing health/crime outcomes as a limitation.
