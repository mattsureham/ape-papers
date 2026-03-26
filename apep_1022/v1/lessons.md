## Discovery
- **Idea selected:** idea_1704 — "settling a dispute" with Hinrichs (2012); SFFA timeliness maximizes relevance
- **Data source:** IPEDS via direct NCES download — Urban Institute API was down (Cloudflare 500s), so switched to bulk CSV files. Handled pre/post-2008 race category change and efalevel structure change across years.
- **Key risk:** Few treated clusters (6 states) limiting inference precision

## Execution
- **What worked:** The TWFE vs CS comparison delivered exactly the "settling the dispute" finding the tournament rewards. CS shows -3.2 pp (p < 0.002) vs TWFE -1.3 pp (insignificant). For Hispanic specifically, CS = -1.0 pp vs TWFE = 0.0 pp — TWFE completely misses it because Hispanic-heavy states (AZ, OK) adopted late. Sun-Abraham confirms independently.
- **What didn't:** Cascade analysis by selectivity failed — admissions data only available for ~480/721 institutions, and treated institutions concentrated in a few quintiles. Used institution size instead, but only "Large" group had enough treated units. The original idea's earnings analysis (ACS) was out of scope for V1.
- **Review feedback adopted:** Acknowledged pre-trend noise (oscillating, not trending; mean positive = conservative), added few-cluster inference paragraph with Cameron et al. (2008), flagged Nebraska's small sample. Reviewers wanted private institution placebo and Goodman-Bacon decomposition — deferred to V2.
