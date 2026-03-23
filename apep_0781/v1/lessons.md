## Discovery
- **Idea selected:** idea_1553 — UI taxable wage base increases and employer separation behavior
- **Data source:** Census QWI API (state-industry-quarter) — 460/460 API calls successful
- **Key risk:** Triple-diff collinearity when `post_increase` = 0 for all controls

## Execution
- **What worked:** QWI API reliable at scale. Null finding is clean and precisely estimated. Pre-trends flat.
- **What didn't:** Initial DDD specification collinear — fixed by using common post period instead of state-specific post_increase for interaction terms.
- **Review feedback adopted:** TBD (reviews in progress)
