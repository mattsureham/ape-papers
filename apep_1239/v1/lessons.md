## Discovery
- **Idea selected:** idea_1308 — Swiss NFA fiscal equalization reform (conditional → unconditional transfers)
- **Data source:** BFS PXWeb API (inter-cantonal migration) — worked well once variable encoding was fixed
- **Key risk:** N=26 cantons and 2008 GFC confound; pre-trends turned out to be the binding constraint

## Execution
- **What worked:** BFS PXWeb API for migration data was reliable and validated against smoke test. Continuous-treatment DiD design was appropriate for the common-timing, heterogeneous-intensity setting.
- **What didn't:** EFV expenditure data was not accessible through BFS PXWeb, narrowing scope from the manifest's "spend, save, or migrate" agenda to migration only. Pre-trends completely invalidated the naive DiD.
- **Review feedback adopted:** Softened causal language from "no effect" to "effect not identified." Added MDE discussion. Acknowledged scope narrowing and Lastenausgleich omission. All three reviewers independently flagged the same core issues — strong validation that the diagnostics were correctly identifying the problem.

## Key lessons
- Pre-existing convergent trends across Swiss cantons make fiscal federalism DiD designs treacherous. Any future NFA paper needs to either extend the pre-period back to 1971 or find a design that sidesteps the trend (e.g., RDD around the Resource Index = 100 threshold).
- A standard TWFE coefficient with p=0.008 was completely spurious — a vivid reminder that pre-trend diagnostics are non-negotiable.
