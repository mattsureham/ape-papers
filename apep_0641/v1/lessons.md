## Discovery
- **Idea selected:** idea_0095 — Salary history bans + QWI industry decomposition; first-order stakes (gender pay gap), sharp identification (staggered DDD), novel angle (industry heterogeneity)
- **Data source:** Census QWI via Azure Parquet — DuckDB queries required CAST() on all columns (BIGINT not VARCHAR); multi-industry API calls return HTTP 204
- **Key risk:** State-level aggregation loses county variation; reviewers flagged this consistently

## Execution
- **What worked:** Triple-difference design produced striking heterogeneity (positive in high-gap, negative in low-gap industries); statistical discrimination framing resonated with reviewers
- **What didn't:** Gemini review model ID (`google/gemini-3-flash`) not available on OpenRouter; `weighted.mean()` in dplyr `summarise()` breaks when NA patterns differ between x and w — must filter valid indices explicitly
- **Review feedback adopted:** Added all 20 industries to Table 2, threshold sensitivity analysis, aggregate welfare calculation, limitations section on county-level and race analysis design, strengthened mechanism discussion
- **Review feedback deferred:** County-level re-estimation (too heavy for V1), formal DDD event study for interaction term, job-posting data from Lightcast
