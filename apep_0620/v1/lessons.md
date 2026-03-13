## Discovery
- **Idea selected:** idea_0608 — Denmark's 1986–1998 refugee dispersal → second-generation adult outcomes (first cohorts now 25–40)
- **Data source:** Statistics Denmark StatBank API (free, no auth) — FOLK1C, RAS200, HFUDD11, BEF3
- **Key risk:** 2008 immigrant share confounds quasi-random dispersal with subsequent endogenous migration

## Execution
- **What worked:** StatBank API data confirmed and rich (employment by ancestry × municipality × age). Placebo test on Danish-origin employment cleanly separates community effects from local labor market conditions.
- **What didn't:** BEF3 historical data only overlaps with 59 of 104 current municipalities (2007 reform). Change-based specification on subsample does not support clean causal story — pre-dispersal levels dominate.
- **Review feedback adopted:** All 3 reviewers flagged causal language overstating what OLS on 2008 immigrant share can identify. Reframed paper as descriptive/associational evidence. Toned down abstract, intro, results, and conclusion. Fixed internal inconsistencies (municipality count: 100 consistently, threshold: 20 descendants). Reinterpreted placebo more cautiously (p=0.10 is marginal, not a strong null). Removed inappropriate comparisons to Chetty-Hendren/MTO. Added explicit discussion of reverse causality through descendant mobility. Honestly acknowledged that change-based specification failure suggests pre-existing patterns dominate.

## Key Findings
- 1 SD ↑ immigrant concentration → +3.3 pp descendant employment, +2.7 pp tertiary education
- Placebo on native employment: positive but marginally insignificant (p=0.10) — suggestive, not definitive
- Positive direction contradicts "ethnic enclave trap" — consistent with network benefits
- Honest about identification limitation: cross-sectional, not causal; sorting likely contributes

