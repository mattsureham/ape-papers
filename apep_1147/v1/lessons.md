## Discovery
- **Idea selected:** idea_1374 — RTW × racial earnings gap, novel angle on well-studied policy
- **Data source:** QWI race panel on Azure — zero fetch risk, 161K rows, 9 states
- **Key risk:** Few treated clusters (4 states)

## Execution
- **What worked:** QWI data on Azure was seamless. DDD specification with saturated FE structure identified cleanly. Placebo and leave-one-out confirmed stability.
- **What didn't:** BigQuery ADC not configured, forcing pivot from patent examiner idea. CS DiD failed on unbalanced panel. WCB incompatible with fixest `^` FE notation.
- **Review feedback adopted:** Added caveats about urban heterogeneity (significant large negative SDE), few-cluster limitations, and earnings vs. wages distinction.
