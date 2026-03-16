## Discovery
- **Idea selected:** idea_0151 (originally claimed idea_0610, pivoted after OSHA data API failure)
- **Data source:** Azure QWI (derived/qwi/sa/ns/*.parquet) — 123M rows, confirmed working. County aggregation to state level required.
- **Key risk:** Insignificant average DDD effect; compensated by strong heterogeneity (retail, age gradient)
- **Pivot lesson:** idea_0610 (OSHA inspections) failed because DOL enforcement data API was restructured into a JavaScript SPA with no REST endpoints. Smoke test had confirmed HTTP 200 for QWI but the OSHA "ITA" data was injury data, not inspection data. Always verify the SPECIFIC data needed, not just that "some data from this source" is accessible.

## Execution
- **What worked:** QWI on Azure is gold — 123M rows loaded cleanly via DuckDB in ~3 minutes. The DDD with three-way FEs (state×industry, state×quarter, industry×quarter) is computationally fast in fixest. The age heterogeneity gradient was stunning and exactly as theory predicts.
- **What didn't:** CS-DiD (`did` package) failed with "argument of length 0" errors due to small groups in the staggered design. Switched to fixest::sunab() for event study, which worked cleanly. The modelsummary package now outputs tabularray format by default, which requires additional LaTeX packages; had to switch to manually generated LaTeX tables.
- **Review feedback adopted:** (1) Reframed paper around heterogeneity rather than insignificant average; (2) Added detailed pre-trend coefficients to validate parallel trends; (3) Strengthened accommodation/food null explanation with three distinct mechanisms (informal arrangements, non-PSL turnover drivers, tips-based compensation).
