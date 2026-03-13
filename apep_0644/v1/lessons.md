## Discovery
- **Idea selected:** idea_0661 — Pay transparency mandates and employer labor flow adjustment via QWI
- **Data source:** QWI via Azure Blob Storage — fetched ~2.4M rows in minutes, no API issues
- **Key risk:** Only 4 treated states means few-cluster inference is unreliable; reviewers flagged this heavily

## Execution
- **What worked:** QWI data from Azure was clean and complete. Callaway-Sant'Anna ran smoothly on state-industry-quarter panels. 21 industries × 52 states = 1,051 panels gave enough variation for the estimator.
- **What didn't:** State-level aggregation (necessary for matching treatment level) meant only 4 treated clusters. All three reviewers flagged this as the main weakness. A county-level border design for Colorado should have been the headline specification.
- **Review feedback adopted:** (1) Moderated language about "precisely estimated null" given few treated states; (2) Added compositional caveat to earnings result; (3) Added pre-treatment event study table; (4) Noted few-cluster inference limitation in empirical strategy section.

## Key Lesson
When treatment varies at a high level (state), even massive micro-data (2M obs) doesn't help with inference. The county-level border design was available and should have been primary rather than relegated to robustness. Future papers with state-level treatment should lead with the sharpest sub-state variation.
