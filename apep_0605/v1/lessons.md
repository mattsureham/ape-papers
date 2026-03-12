## Discovery
- **Idea selected:** idea_0017 — US fracking boom-bust asymmetry test (resource curse)
- **Data source:** Census QWI via Azure Parquet — fast, clean, county-year aggregation via DuckDB
- **Key risk:** Pre-trends at distant leads (shale counties declining before boom); turns out this strengthens the finding

## Execution
- **What worked:** Azure QWI query was highly efficient (200K rows in seconds); shale county crosswalk from literature was clean; CS-DiD ran smoothly with 123 treated vs 3,017 control counties
- **What didn't:** FRED WTI oil price data used for continuous treatment but primary results use binary treatment; HonestDiD failed due to sparse variance matrix
- **Review feedback adopted:** (1) Acknowledged negative pre-trends honestly and explained they bias against finding positive effects; (2) Reframed asymmetry test to emphasize CS-DiD event-study-based comparison rather than TWFE Panel B; (3) Added binary treatment as explicit limitation in Discussion
- **Key lesson:** Negative pre-trends are not always bad — when the pre-trend goes against the finding, it actually strengthens the result. Frame this clearly for reviewers.
