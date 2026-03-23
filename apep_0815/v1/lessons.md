## Discovery
- **Idea selected:** idea_1771 — FRA SNAP ABAWD age expansion, originally T-MSIS health outcomes
- **Data source:** Census QWI via API — multi-value agegrp returns HTTP 204 (must loop per age group, same as multi-industry bug)
- **Key risk:** Age dilution — QWI reports 45-54 as single bin, only 50-54 newly treated

## Execution
- **What worked:** DDD design with 22 pre-treatment quarters provided excellent power for pre-trend detection; event-study immediately revealed the pre-trend issue; de-trending produced a clean null
- **What didn't:** Pivoted from T-MSIS health outcomes (insufficient age data in our extract) to QWI employment — lost the novel health cost-shifting angle
- **Key methodological insight:** Pre-trends in DDD are more common than assumed; the naive DDD looked significant (3.9%***) but was entirely an artifact of differential pre-trends

## Review feedback adopted
- Added Rambachan-Roth bounds reference for de-trending robustness
- Added first-stage context paragraph (SNAP participation declines from literature)
- Explicit LATE rescaling with confidence interval for the diluted age bin
- Justified employment focus as "logically prior" test to health cost-shifting
