## Discovery
- **Idea selected:** idea_1521 — PNTR × Black-White manufacturing earnings gap (DDD). Chosen for sharp identification (1930s NTR gaps), novel data (QWI race panel), and first-order question (trade × racial inequality).
- **Data source:** Azure QWI rh/n3 panel — 5.1M rows. Three gotchas: race codes A0-A7 (not WH/BK), industry codes are integers at n3 level, and ethnicity dimension must be filtered to A0.
- **Key risk:** Coefficient interpretation in saturated FE model with race-level data. The NTR×Black level (-1.14) dominates the triple interaction, making the DDD coefficient hard to interpret.

## Execution
- **What worked:** The BW gap specification (collapsing the race dimension) gives a clean, interpretable result (-0.084 per unit NTR gap). The event study shows textbook-flat pre-trends. The mechanism decomposition (employment, hires, separations) tells a coherent extensive-margin story.
- **What didn't:** The race-level DDD specification suffers from sign instability across FE structures. Column 1 (fewer FEs, explicit lower-order terms) gives +0.96 on the triple interaction, while Column 3 (saturated FEs) gives -1.25. All three reviewers flagged this. For future triple-diff papers with race as a dimension, use the gap specification as the main result.
- **Review feedback adopted:** (1) Made Column 4 (BW gap) the primary specification. (2) Acknowledged two-way clustering as more conservative. (3) Softened mechanism coefficient reporting. (4) Better framed the Asian placebo (attenuated but not null).
