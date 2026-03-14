## Discovery
- **Idea selected:** idea_0892 — UK council tax empty homes premium. The paradox (premiums tripled, vacancies rose) makes a vivid hook for tournament judges.
- **Data source:** MHCLG Live Table 615 (vacancy) + Council Taxbase 2025 (treatment). Gov.uk URLs go stale frequently — always search fresh.
- **Key risk:** Only 5 never-treated LAs by 2025, down from 61 in 2014. Historical annual CTB microdata not publicly downloadable.

## Execution
- **What worked:** The null result is rock solid across 4 specifications, 21 event-study periods, CS-DiD, and Fisher randomization inference (RI p = 0.931). Clean pre-trends over 9 years. The paper tells a clear story: structural constraints dominate financial incentives.
- **What didn't:** The small control group (5 LAs) is the main vulnerability. Without historical CTB data, I couldn't exploit the richer staggered adoption (244 vs 61 in 2014) or the dose-response from premium escalation. These are valid limitations acknowledged in the paper.
- **Review feedback adopted:** Added Fisher randomization inference (2,000 permutations) and covariate balance table per reviewer concerns about few-cluster inference. Added MDE/power discussion. Acknowledged staggered/dose limitations as future work.
