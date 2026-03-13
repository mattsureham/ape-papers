## Discovery
- **Idea selected:** idea_0143 — E-Verify mandates and Hispanic employment using QWI administrative data
- **Data source:** Census QWI race/ethnicity tabulations from Azure Blob Storage — fetched 40M rows, aggregated to state-level
- **Key risk:** Only 10 treated states limits RI power; concurrent enforcement (287g, Secure Communities) could confound

## Execution
- **What worked:** QWI from Azure was seamless — no API rate limits, instant aggregation via DuckDB. Sun-Abraham event study clean and interpretable. Industry heterogeneity (high-immigrant -10% vs low-immigrant null) strongly validates the mechanism.
- **What didn't:** Callaway-Sant'Anna `did` package failed with single-unit cohorts (each state is its own treatment cohort). Had to switch to fixest::sunab(). DDD specification had sign interpretation issues due to collinearity — SA event study is much cleaner for this design. Memory limits (16GB) required aggregating to state level in DuckDB rather than loading raw county data.
- **Review feedback adopted:** (1) Tempered all significance claims to acknowledge RI p=0.166 — abstract, results, discussion, conclusion now use "suggestive evidence" language (all 3 reviewers). (2) Added hiring/separation flow decomposition paragraph showing displacement operates through reduced hiring, not increased separations (all 3 reviewers). (3) Added magnitude plausibility back-of-envelope calculation scaling by unauthorized share (~150K displaced consistent with 2M unauthorized Hispanic workers in mandate states at 50-80% compliance). (4) Acknowledged county-industry granularity as future work and QWI ethnicity classification limitations in Discussion caveats. Did NOT implement: DDD re-specification (collinearity issues persist), county-level regressions (memory constraints), dose-response treatment intensity (insufficient variation in scope).

## Technical Notes
- QWI race/ethnicity endpoint: `derived/qwi/rh/ns/*.parquet` in Azure
- For few-cluster DiD designs, RI with 500 permutations is essential but may not reject at 10% with only 10 clusters
- The `did` R package requires >1 unit per treatment cohort; fixest::sunab handles singletons
