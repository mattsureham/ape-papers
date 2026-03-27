## Discovery
- **Idea selected:** idea_1918 — Bridge sufficiency rating bunching at federal funding threshold (Goodhart's Law in infrastructure)
- **Data source:** FHWA National Bridge Inventory — freely downloadable CSVs, 52 state files per year, 2000-2018
- **Key risk:** Mechanical bunching from the SR formula rather than strategic behavior

## Execution
- **What worked:** The bunching is massive and immediately visible in raw data (38% density drop at SR=50). NBI data download was straightforward. Poisson bootstrap for SEs was much faster than ID-resampling bootstrap.
- **What didn't:** Original bootstrap (resampling 780K bridge IDs with cartesian merge) was computationally infeasible. Had to pivot to Poisson bootstrap on pre-aggregated state-year-SR counts. Polynomial sensitivity is genuine (1.55-2.39 across orders 5-9).
- **Review feedback adopted:** Moderated causal language ("confirms" → "consistent with"), added mechanical explanations paragraph, explained owner heterogeneity patterns, added explicit limitations section. State-level HBP exposure heterogeneity is the obvious V2 improvement.
