## Discovery
- **Idea selected:** idea_0846 — IRS Form 990 threshold reform, testing whether disclosure costs constrain nonprofit growth
- **Data source:** IRS EO BMF (1.9M orgs) + ProPublica Nonprofit Explorer API (5,387 orgs fetched)
- **Key risk:** Pre-2010 data scarcity forced pivot from pre/post DiD to two-threshold comparison

## Execution
- **What worked:** ProPublica API at ~87% hit rate, solid 15K+ obs panel; bunching estimation with polynomial counterfactual; honest null framing
- **What didn't:** AWS IRS 990 index (defunct), pre-reform data too sparse for original DiD design; had to completely redesign identification mid-execution
- **Major pivot:** Original plan was pre/post DiD around 2010 reform. ProPublica data sparse before 2010. Redesigned as cross-sectional comparison: bunching at $200K (new threshold) vs $100K (freed threshold), plus DiD comparing near-threshold vs mid-range orgs
- **Review feedback adopted:** All three reviewers flagged the identification gap (no 2010 reform exploitation). Added explicit acknowledgment of data pivot, power calculation with MDE, and tightened causal claims throughout. Cannot fix the fundamental design limitation in V1 — this would require accessing pre-2010 data (e.g., IRS SOI microdata or historical NCCS files) which was not feasible within the API-based workflow.
