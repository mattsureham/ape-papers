## Discovery
- **Idea selected:** idea_0964 — UK calorie labeling mandate creates cross-border natural experiment (England vs Scotland)
- **Data source:** Companies House bulk data (5.7M companies, free, no auth) — URL format required web fetch to discover exact date pattern
- **Key risk:** Pre-trend noise from COVID; only 2 country units

## Execution
- **What worked:** Triple-difference design with 5 placebo sectors provides clean null result with precise confidence intervals. Companies House data is excellent for entry analysis — reliable SIC codes, incorporation dates, jurisdiction classification via company number prefix.
- **What didn't:** Dissolution data is absent from the bulk snapshot (only active companies included). The RDD at the 250-employee threshold proposed in the idea manifest was infeasible — Companies House bulk CSV doesn't include employment counts. Pivoted to cross-border DiD.
- **Review feedback adopted:** (1) Separated England from Wales — Wales didn't adopt the mandate but was grouped with England via Companies House data; used RegAddress.Country + postcode areas to classify. (2) Added permutation inference (999 draws, p = 1.000) to address the 2-jurisdiction inference concern. (3) Reframed from "entry deterrence" to "spillover entry deterrence on exempt firms" since the regulation targets 250+ employee firms while incorporations are small businesses. (4) Toned down "precisely estimated null" language throughout.
