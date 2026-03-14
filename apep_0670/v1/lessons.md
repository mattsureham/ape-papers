## Discovery
- **Idea selected:** idea_0467 — Comment period length and public participation in federal rulemaking
- **Data source:** Federal Register API (free, no key needed) + regulations_dot_gov_info cross-reference for comment counts
- **Key risk:** Endogenous period assignment (agencies give longer windows to more complex rules)

## Execution
- **What worked:** The FR API's `regulations_dot_gov_info.comments_count` field provides comment counts directly, eliminating the need for slow Regulations.gov API calls. One-stop data source.
- **What didn't:** Initial attempt to use Regulations.gov API separately wasted ~40 minutes on rate-limited fetching. The `fields[]` parameter in httr2 requires `.multi = "explode"` for repeated params. The FR API caps results at 10,000 (got 2019-2023 only, not full 2010-2023 range).
- **Key finding:** Comment period length is associated with 1.7% more comments per additional day (with agency×year FE, clustered SEs). Effect driven entirely by non-significant rules. Elasticity = 0.67.
- **Placebo concern:** Comment days significantly predicts page length (0.014, p<0.001), meaning period assignment is not fully quasi-random. Controls absorb most of this, but causal language tempered accordingly.
- **Review feedback adopted:** Clustered SEs at agency-year level (2.5x larger, still significant at 1%). Tempered causal language throughout. Acknowledged placebo test concern honestly.

## Technical Lessons
- Federal Register API: use `.multi = "explode"` with `fields[]` parameter in httr2
- Federal Register API: 10,000 result cap per query — split date ranges for full coverage
- `regulations_dot_gov_info` field gives direct comment counts without separate API calls
- `slice_sample(n = min(200, n()))` fails in grouped dplyr — use `group_modify()` instead
