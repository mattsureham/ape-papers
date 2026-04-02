## Discovery
- **Idea selected:** idea_1389 — HEERF ($76B emergency higher ed relief) with Pell-share formula as exogenous variation. Zero existing APEP papers on HEERF.
- **Data source:** IPEDS via local DuckDB copy (from Azure). All data present and well-structured.
- **Key risk:** Pell-share formula may proxy for institutional vulnerability, not just HEERF exposure.

## Execution
- **What worked:** The reduced-form design (predicted HEERF × Post) is clean and transparent. Event study shows textbook clean pre-trends for enrollment. The 2022 enrollment cliff finding is striking and novel.
- **What didn't:** Original Bartik IV design failed — weak first stage because federal revenue includes research grants that swamp HEERF. Pivoting to reduced form was the right call. Tuition pre-trends are contaminated. Log enrollment specification yields null, suggesting the level effect is driven by large institutions.
- **Review feedback adopted:** Fixed number discrepancies between text and tables, fixed SDE table SD(X)=0 issue, added honest caveat about log-enrollment null, strengthened "what this design cannot identify" paragraph.

## Key Takeaway
HEERF formula intensity predicts a sharp post-2022 enrollment cliff but near-zero tuition pass-through. The temporal pattern (null during HEERF, crash after) is the most interesting finding — it suggests a "windfall trap" where temporary funds cushion but don't protect. The log-enrollment null is a meaningful limitation that should be addressed in any revision.
