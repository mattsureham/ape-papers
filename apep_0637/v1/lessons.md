## Discovery
- **Idea selected:** idea_0117 — Patent examiner leniency IV for defensive patenting (strongest first-stage IV in the idea database)
- **Data source:** Google BigQuery PatEx (USPTO examination data) — worked flawlessly, 1.7M observations extracted in ~2 minutes
- **Key risk:** Class-level aggregation of outcome variable (total USPC class filings) may be too coarse to detect firm-level strategic responses

## Execution
- **What worked:** BigQuery extraction was fast and reliable. The examiner leniency IV produced an extraordinarily strong first stage (F > 16,000). The 2SLS null result is clean and precise across all specifications.
- **What didn't:** The USPC class-level outcome is too aggregate — all three reviewers flagged this as the main limitation. Future work should link to assignee-level data via Google Patents publications table.
- **Review feedback adopted:** Added class-level clustering robustness (SE actually smaller at 0.049 vs 0.072). Substantially expanded Discussion section to address aggregation limitation and LATE interpretation explicitly.
- **Key lesson:** For examiner IV papers studying competitor responses, firm-level outcomes (not class-level) are essential. The BigQuery publications table has assignee_harmonized data that could enable this.

## Technical Notes
- `filing_date` in PatEx is STRING type, not DATE — use PARSE_DATE
- `small_entity_indicator` is numeric (0/1), not string ("TRUE"/"FALSE")
- `fitstat(fit, "ivf")` only works on IV models, not OLS first-stage regressions
- Permutation inference on 1.7M observations is very slow — use data.table for vectorized within-group permutation, and limit to ~50 permutations for V1
