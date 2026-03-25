## Discovery
- **Idea selected:** idea_1746 — First causal evaluation of the 2021 TFP revision, the largest permanent SNAP expansion
- **Data source:** CPS Food Security Supplement via Census Bureau API — worked perfectly for all 9 years (2015-2023)
- **Key risk:** Emergency Allotment phase-out confounds the TFP effect; addressed via triple-diff and restricted sample

## Execution
- **What worked:** Census API for CPS FSS microdata was reliable and fast; ACS via tidycensus for treatment intensity; extended pre-period (2015-2019) for robust pre-trends
- **What didn't:** Initial PERRP coding assumption was wrong (codes changed between 2018-2019 and 2020+); HRFS12M1 uses 3-level scale in Census API, not 4-level — had to recalibrate food insecurity definition
- **Data surprise:** The Census API returns CPS microdata at the person level, requiring careful filtering to reference persons and household-level deduplication
- **Review feedback adopted:** Added back-of-envelope TFP vs EA magnitude calculation (~$36B vs ~$90-100B), formal MDE calculation, acknowledged food inflation limitation, strengthened heterogeneity discussion with Bitler & Seifoddini reference
