## Discovery
- **Idea selected:** idea_1560 — New Deal WPA × racial occupational mobility using 36.8M triple-linked MLP panel
- **Data source:** IPUMS MLP v2 (Azure), Fishback-Kantor-Wallis county spending (Harvard Dataverse)
- **Key risk:** Pre-existing differential in 1920-1930 threatens causal interpretation

## Execution
- **What worked:** The sign flip from spec 2 (+0.12) to spec 3 (-0.18) when adding occupation FE is the paper's most compelling insight — reveals that raw positive association is compositional. South vs Non-South split (−0.31 vs 0.04) provides strong mechanism test. 128GB RAM enabled full in-memory panel of 11M observations.
- **What didn't:** Pre-trend coefficient (-0.107) is 58% of main effect — had to be honest about this. Fishback data only has total ND spending, not WPA-specific — forced treatment-mechanism alignment issue.
- **Review feedback adopted:** (1) Tempered causal language throughout — "associated with" not "caused"; (2) Aligned title/framing with total ND spending rather than work relief specifically; (3) Fixed magnitude interpretation — removed incorrect 19% claim; (4) Added state-clustered SEs (t=-2.50, still significant); (5) Reframed women result honestly rather than as successful placebo; (6) Fixed OCCSCORE vs Duncan SEI definition inconsistency.
