## Discovery
- **Idea selected:** idea_1784 — Panic of 1907 + MLP occupational scarring. Selected after idea_1767 (pharmacy closures) failed due to data limitations and 4 other ideas had too much overlap with existing APEP papers.
- **Data source:** IPUMS MLP linked panel 1900-1910 on Azure (33.9M records, 8.6M prime-age men after filtering). All data on Azure — zero API calls needed.
- **Key risk:** State-level treatment classification is coarser than ideal county-level correspondent banking network data from Frydman et al. (2023).

## Execution
- **What worked:** DuckDB queries against Azure Parquet files were fast and reliable. DDD design (panic severity × banking-dependent sector) with state FE cleanly identifies within-state, across-sector variation. Placebo (literacy) and falsification (agriculture) both support the identification.
- **What didn't:** Original pharmacy idea (idea_1767) consumed ~2 hours before failing: T-MSIS OT file lacks pharmacy Rx claims, chain pharmacy NPIs don't deactivate, SNAP API requires auth. Lesson: verify data structure matches empirical design before committing.
- **Review feedback adopted:** Softened causal language throughout per all three reviewers. Added explicit limitation about state-level treatment and future county-level upgrade path. Did not implement county-level Frydman data (not available for V1).
