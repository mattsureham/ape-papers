## Discovery
- **Idea selected:** idea_0815 — IRS Form 990 bunching. Chose for clean identification, massive sample, and built-in placebo/reform tests.
- **Data source:** IRS EO BMF (4 regional CSVs, 1.94M orgs) — downloaded cleanly, exact revenue amounts.
- **Key risk:** Cross-sectional snapshot limits ability to exploit 2010 reform as panel design.

## Execution
- **What worked:** The bunching is unambiguous (b=1.52, t=3.91) with a clean placebo (t=0.80). The heterogeneity story — religious orgs and small-asset orgs driving the result — fell out naturally and validates the mechanism.
- **What didn't:** bit64::integer64 conversion to numeric is silently broken in R unless you explicitly load the bit64 package. `as.numeric()` on integer64 produces garbage (4e-313). Fix: `as.numeric(as.character(x))` with bit64 loaded. This will bite any paper using data.table with large integer columns.
- **Review feedback adopted:** Reframed from "disclosure" to "compliance burden" (both forms are public). Added two-dimensional filing rule discussion (revenue AND assets). Expanded excess/missing mass imbalance discussion. Tightened language from "manipulation" to "behavioral response."
