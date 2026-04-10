## Discovery
- **Idea selected:** idea_0104 — Germany's Vorrangprüfung suspension. Chosen for sharp geographic variation (133 vs 23 districts), mechanical assignment in Bavaria, and built-in placebo from recognized refugees.
- **Data source:** Eurostat NUTS-3 regional accounts (employment, GDP, population). Foreign-citizen population unavailable at NUTS-3 level.
- **Key risk:** Aggregate employment too coarse to detect effects on a small treated subpopulation (~2% of workforce). This risk materialized — all reviewers flagged it.

## Execution
- **What worked:** Eurostat data access was flawless (400 NUTS-3 regions, 10 years). Treatment mapping from Agenturbezirk to NUTS-3 was clean. Pre-treatment balance was excellent. Event study showed flat pre-trends. The null result is robust across all specifications.
- **What didn't:** Missing refugee-specific BA Statistik data limited the paper to aggregate outcomes. The within-Bavaria RDD was hobbled by NUTS-2 level unemployment (too coarse for a proper running variable). Foreign population data unavailable at NUTS-3, eliminating a potential mechanism outcome.
- **Review feedback adopted:** Softened title and claims, added power calculations, rewrote discussion to distinguish aggregate null from individual-level effects, explicitly listed data limitations and paths for future work. Kept the paper honest about what aggregate data can and cannot identify.

## Key lesson for future papers
When the treated population is small relative to the unit of observation, aggregate outcomes will produce uninformative nulls. Always check the treated-population share before committing to an outcome variable. If it's below 5%, either find outcome data that directly measure the treated group, or reframe the paper explicitly as a general-equilibrium spillover study.
