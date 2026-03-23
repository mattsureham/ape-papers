## Discovery
- **Idea selected:** idea_1490 — Ireland's RPZ staggered rollout with CSO public data
- **Data source:** CSO PxStat table RIQ02 — JSON-stat API worked after switching from CSV (403) and rjstat (parsing failure)
- **Key risk:** County-level aggregation when policy was LEA-level; RTB RPZ page is now 404

## Execution
- **What worked:** Perfectly balanced panel (26×55), C-S estimator recovered clear growth effect, Bacon decomposition told a compelling TWFE-bias story
- **What didn't:** rjstat R package couldn't parse the JSON-stat; had to use Python wrapper. Bacon table computation had a weighted.mean bug producing wrong values (fixed manually)
- **Review feedback adopted:** Strengthened threats-to-validity section with specific pre-trend evidence, control group erosion discussion, and measurement error/attenuation argument
