## Discovery
- **Idea selected:** idea_0955 — Smart motorway conversions and road safety. Zero academic causal studies despite massive public controversy and programme cancellation. STATS19 data is deep and accessible.
- **Data source:** DfT STATS19 via stats19 R package — 9M+ collision records, 140K motorway collisions. Key gotcha: column names changed across versions (accident_year → collision_year).
- **Key risk:** Constructing section-level treatment panel from government publications without GIS geometry data. Only 14 of 28 sections got reliable coordinate-based matching.

## Execution
- **What worked:** STATS19 data is excellent. The staggered DiD design with 11 cohorts produces clean identification. Leave-one-out analysis is remarkably stable. Wild cluster bootstrap provides rigorous inference for 32 clusters.
- **What didn't:** Bounding-box section assignment is the weakest link. Without official road geometry data, half the sections couldn't be reliably matched. A future version should use National Highways GIS shapefiles for precise section-to-collision matching.
- **Review feedback adopted:** Reframed CS as primary estimator (TWFE as benchmark), moderated all causal claims, acknowledged the imprecision of CS estimate, expanded limitations discussion. All three reviewers correctly flagged the TWFE/CS discrepancy as the central interpretive issue.

## Key Takeaway
In staggered DiD papers, always lead with the heterogeneity-robust estimator even when TWFE produces a cleaner result. Reviewers will rightly question why you're featuring the estimator with known bias concerns.
