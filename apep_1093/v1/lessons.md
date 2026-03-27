## Discovery
- **Idea selected:** idea_1631 — Pay transparency mandates and racial new-hire earnings gap. Chose for novel racial angle (literature is entirely gender-focused), data already in Azure, and strong staggered adoption across 6 states.
- **Data source:** QWI race/ethnicity × 3-digit NAICS from Azure Blob Storage (141M rows pre-filter). Required fixing connection string loading (bash truncates at semicolons) and column naming (columns are `race` not `race_ethnicity`, files are lowercase `co.parquet`).
- **Key risk:** Few treated states (7) for state-clustered inference; mitigated by 2,649 treated county-industry panels and wild bootstrap.

## Execution
- **What worked:** Azure DuckDB pathway for QWI data was efficient once connection issues resolved. The gap regression (ln(Black) - ln(White)) as the outcome provides a clean single-coefficient estimand. Industry heterogeneity (Table 3) provides a natural mechanism test without a formal DDD.
- **What didn't:** The DDD triple interaction (Treated × Post × HighDisp) is absorbed by county-industry fixed effects — collinearity is expected but reviewers flagged the presentation. Should present industry heterogeneity as separate regressions (as done) rather than claiming DDD.
- **Review feedback adopted:** Added pre-trends discussion (event study coefficients all insignificant), expanded sample selection discussion (41% suppression), gave hiring volume results (White -4.7%, Black unchanged) more prominence with compositional interpretation.
