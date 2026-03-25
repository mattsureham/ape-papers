## Discovery
- **Idea selected:** idea_1461 — State EITC × QWI ethnicity panel triple-difference
- **Data source:** QWI rh panel from Azure Parquet — connection string truncation bug cost ~15 min
- **Key risk:** EITC is heavily studied; novelty rested entirely on QWI ethnicity angle

## Execution
- **What worked:** Azure Parquet → R pipeline was fast once connection fixed. Triple-diff with high-dimensional FEs in fixest was computationally trivial (13K obs, 612 units). CS estimator confirmed TWFE results cleanly.
- **What didn't:** Payroll/earnings data was entirely missing in the QWI ethnicity aggregation (all NAs), forcing exclusion of the earnings outcome. The continuous treatment specification was underpowered.
- **Surprise:** The core result inverted expectations — EITC reduces (not increases) Hispanic employment in NAICS 56. This turned a routine "policy increases employment" paper into a more interesting "sectoral reallocation" story.
- **Review feedback adopted:** Toned down causal claims about "sorting dividend" to more cautious language about compositional shifts. Added explicit QWI variable definitions. Clarified treatment coding (29 ever-treated, 24 post-2000 in CS). Added discussion of concurrent policy confounders as a limitation.
