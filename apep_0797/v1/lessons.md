## Discovery
- **Idea selected:** idea_1454 — Niger ECOWAS sanctions create a within-market commodity contrast (tradable rice vs local millet)
- **Data source:** WFP VAM via HDX — clean download, excellent coverage (55 Niger + 62 BFA markets, monthly, 2021-2024)
- **Key risk:** Burkina Faso's own 2022 coup could contaminate the control; mitigated by clean placebo test

## Execution
- **What worked:** The triple-diff design delivered strong, clean results. The commodity-level variation (rice vs millet) is genuinely sharp. The sanctions intensity test (full vs partial lift) provides compelling mechanism evidence. Naming the economic object ("tradability tax") gives the paper a memorable hook.
- **What didn't:** HDX download URLs require CKAN API lookup — the generic `/resource_download/latest` pattern no longer works. Also, `modelsummary` now defaults to `tabularray` format which requires extra LaTeX packages; hand-coded tables were faster.
- **Review feedback adopted:** Added clarification of how saturated FE variation survives, noted demand substitution bias (conservative), acknowledged spatial heterogeneity as a limitation, discussed Burkina Faso control validity more explicitly.
