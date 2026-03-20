## Discovery
- **Idea selected:** idea_0460 — Norway's press subsidy and voter turnout. Chose for sharp institutional lever (number-two newspaper eligibility), first-order democratic question, and confirmed data access via SSB API.
- **Data source:** SSB API (tables 08243 + 09475 for turnout, 05212 for population) + Medietilsynet Excel subsidy records. SSB API worked flawlessly. Medianorge website (needed for newspaper circulation data / RDD running variable) was inaccessible programmatically.
- **Key risk:** Could not construct the RDD running variable (market share gap) without newspaper-level circulation data for ALL papers (subsidized + non-subsidized). Pivoted from RDD to municipality-level panel OLS.

## Execution
- **What worked:** SSB API is excellent for Norwegian policy research — rich municipality-level data with long panels. Medietilsynet publishes subsidy allocation Excel/PDF files publicly. Newspaper-to-municipality mapping via geographic name matching was surprisingly reliable (75/89 = 84% match rate).
- **What didn't:** The Medianorge website appears dynamically loaded and returned empty HTML on curl. This blocked the intended RDD design. The paper ended up with weaker identification (cross-sectional + panel OLS) than planned (fuzzy RDD at market-rank threshold).
- **Surprising finding:** Treated municipalities have *lower* turnout (-1.1 pp), not higher. The negative association is robust across all specifications but attenuates with population quartile controls. The local/Storting asymmetry (72% larger for local elections) is the most interesting feature.
- **Review feedback adopted:** TBD (reviews in progress)
