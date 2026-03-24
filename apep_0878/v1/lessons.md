## Discovery
- **Idea selected:** idea_0769 — State EITC supplements + QWI race data for wage incidence
- **First attempt failed:** idea_0694 (Swiss GEA 100-employee threshold RDD) — public BFS data lacks firm-size bins at the 100-employee cutoff. Lesson: verify bin granularity before committing to threshold RDDs.
- **Data source:** QWI race×ethnicity (LEHD) from Azure — 1.66M rows fetched successfully
- **Key risk:** Wage incidence might be undetectable at state supplement magnitudes (5-30% of federal credit)

## Execution
- **What worked:** Azure DuckDB connection for large Parquet queries; CS DiD + DDD dual identification strategy gave converging evidence; the DDD absorbed Ohio pre-trend contamination that broke the CS employment estimate
- **What didn't:** Azure connection string gets truncated by shell semicolons — required reading .env directly in R; dplyr 1.1+ sequential evaluation trapped weighted.mean (must compute before aggregating the weight variable)
- **Review feedback adopted:** Added MDE calculation (2.8% detectable, comparable to maximum plausible effect), clarified QWI EarnS is pre-tax employer-reported wages, acknowledged QWI race imputation as potential attenuation bias, explained CS vs DDD employment discrepancy more explicitly
