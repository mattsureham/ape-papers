## Discovery
- **Idea selected:** idea_0325 — Universal License Recognition and labor market flows (QWI)
- **Data source:** Census QWI via Azure Parquet — fast and reliable, 41.5M raw rows
- **Key risk:** COVID overlap with treatment window (2019-2023)
- **Pivot:** Originally attempted idea_0120 (ERPO/firearm mortality) but CDC Mapping Injury API only covers 2019-2024 and FBI SHR requires manual download. Pivoted to QWI-based idea.

## Execution
- **What worked:** DDD design with licensed vs unlicensed sectors produced clean, surprising results — "retention dividend" framing was novel. Azure QWI data fetched cleanly. Pre-trends were flat.
- **What didn't:** County-level analysis not feasible due to QWI suppression in education×industry cells. Gemini flash model failed for review (same issue as apep_0641).
- **Review feedback adopted:** Strengthened identification discussion (DDD parallel trends, confounders), justified state-level aggregation, improved education heterogeneity interpretation acknowledging compositional concerns, added inference caveat about cluster count, expanded welfare discussion with back-of-envelope calculation.
