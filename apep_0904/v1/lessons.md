## Discovery
- **Idea selected:** idea_1867 — Federal procurement SAT bunching, chosen for extreme data richness (5.87M contracts/year), bunching methodology (top-performing in tournament), and multi-threshold migration test
- **Data source:** USAspending.gov API — rate limiting required 1.5s delays between calls; partial-save/resume logic essential for robustness
- **Key risk:** Bunching could be round-number effect, not regulatory — addressed via migration test and placebo thresholds

## Execution
- **What worked:** The migration test is the paper's strongest asset. Bunching at $150K drops from 0.403 to 0.090 after the threshold moves, while $250K bunching rises from ~0 to 0.665. Year-by-year anticipation pattern (starting FY2019) adds credibility.
- **What didn't:** API rate limiting added ~25 minutes to data fetch. $10K bins are wider than ideal for bunching estimation but necessary given API constraints. No agency-level heterogeneity (defense vs civilian) due to additional API calls needed.
- **Review feedback adopted:** Added contract value definition clarification (total current award value, not individual obligations); added back-of-envelope compliance cost calculation ($50M/year in procurement scope sacrificed at $150K); added splitting vs undersizing mechanism discussion; strengthened anticipation narrative.
