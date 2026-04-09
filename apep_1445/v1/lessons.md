## Discovery
- **Idea selected:** idea_2528 — CQC Inadequate threshold RDD, first causal estimate of label effects on care home exit
- **Data source:** CQC bulk ODS download (free, Open Government Licence) — API was blocked (403) but bulk download worked perfectly
- **Key risk:** Discrete running variable (only 16 mass points) makes nonparametric RDD infeasible

## Execution
- **What worked:** Sharp institutional threshold with near-perfect concordance between composite score ≥17 and Inadequate rating. Data fetch trivial once API workaround found. Clean, consistent results across specs.
- **What didn't:** rdrobust fails on 16 mass points — had to switch to parametric local linear regression. Heterogeneity analysis limited because panel-cross merge lost covariate information. Only 113 treated units constrains power.
- **Review feedback adopted:** Added empirical validation of threshold sharpness, acknowledged fuzzy RDD as superior design, expanded limitations on power and panel underutilization, strengthened density discussion.
