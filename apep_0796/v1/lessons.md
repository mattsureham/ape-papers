## Discovery
- **Idea selected:** idea_0985 — Swiss Second Home Initiative RDD; sharp 20% threshold with novel federal housing inventory data
- **Data source:** geo.admin.ch STAC API — clean download of 15 xlsx waves; BFS PXWeb API failed for population (JSON-stat2 parsing); no empty dwelling data available
- **Key risk:** Running variable measured post-treatment (2018 vs 2012 policy) — mitigated by structural nature of housing stock

## Execution
- **What worked:** geo.admin.ch STAC API was perfectly structured — each wave downloadable as xlsx.zip with consistent column names. The rdrobust R package handled everything cleanly. The null-on-composition + positive-on-growth combo created a compelling "regulatory substitution" story.
- **What didn't:** 2017 wave had different xlsx sheet naming (no "ZWG" prefix) and was skipped. BFS PXWeb population query failed — the JSON-stat2 dimension names didn't match expectations. Would need to investigate the actual API schema more carefully.
- **Review feedback adopted:** Added power/MDE discussion, running variable timing caveat, denominator dilution interpretation, and Bonferroni correction for dynamic results.
