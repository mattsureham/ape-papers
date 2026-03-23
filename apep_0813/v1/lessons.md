## Discovery
- **Idea selected:** idea_1308 — Swiss NFA reform (2008), conditional → unconditional transfers. Chosen for clean institutional setting, transparent treatment formula, and reliable BFS data access.
- **Data source:** BFS PXWeb API (demographic balance table px-x-0102020000_101). Fetched migration and population from a single 5-dimensional table (year × canton × citizenship × sex × demographic component). NFA treatment from published EFV Wirksamkeitsbericht.
- **Key risk:** Pre-existing convergence trends confounding the DiD identification.

## Execution
- **What worked:** BFS API worked flawlessly — no authentication needed, clean json-stat2 output. The 5-dimension structure was initially confusing but once understood, it's a single API call for all needed data. R analysis pipeline ran cleanly. Wild cluster bootstrap and RI both produced results.
- **What didn't:** Event study revealed significant pre-trends — the migration convergence was already underway before 2008. Placebo at 2006 produced a coefficient *larger* than the main estimate. This substantially weakens causal claims. Could not get cantonal expenditure data from the same API, limiting the paper to migration outcomes only.
- **Review feedback adopted:** Narrowed conditionality framing (all 3 reviewers flagged it as too strong without spending data). Added post-2004 referendum test that showed anticipation effect (β = 2.94, p < 0.001). Added extra placebos (2003, 2005). Reframed conclusion as "Tiebout sorting responds to reform process, not implementation date." Did NOT add expenditure/tax data (infeasible for V1 — reviewers noted this should be addressed in revision).
