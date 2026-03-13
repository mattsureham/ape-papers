## Discovery
- **Idea selected:** idea_0211 — Norway's 2022 secondary dwelling wealth tax reform provides clean dose-response variation across municipalities
- **Data source:** SSB JSON-stat2 API — robust public API but JSON-stat2 dimension ordering (row-major) clashes with R's expand.grid (column-major); required careful reversal
- **Key risk:** Only 2 pre-treatment years in post-merger panel (2020-2021); Norway's 2020 municipal merger makes pre-2020 codes inconsistent

## Execution
- **What worked:** Continuous treatment (secondary dwelling share) provides strong dose-response; 356 municipalities gives sufficient power; monotonic quartile pattern is compelling
- **What didn't:** SSB API metadata parsing was fragile (data.frame vs list); initial full-panel analysis (2010-2024) showed massive pre-trends that turned out to be the 2020 merger artifact, not real pre-trends
- **Critical fix:** JSON-stat2 values are stored in row-major order (last dimension varies fastest) but R's expand.grid has first dimension varying fastest. Must reverse dimension order in expand.grid then reverse columns back. Without this fix, ALL values map to wrong cells.
- **Surprising result:** Reform exposure → MORE construction (not less), suggesting portfolio rebalancing away from taxed secondary dwellings toward new construction
- **Review feedback adopted:** (1) Added magnitude discussion contextualizing implied elasticity vs literature (all 3 reviewers flagged this). (2) Tempered abstract and conclusion claims about "challenging conventional wisdom" — now presented as conditional/one interpretation. (3) Expanded limitations to discuss post-pandemic tourism recovery as confounder, short pre-period, need for permit type disaggregation. (4) Not feasible in V1: extending panel to pre-2020 (requires merger concordance tables), disaggregating permits by type (data not in SSB API).
