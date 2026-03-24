## Discovery
- **Idea selected:** idea_0751 — RON laws offer clean staggered adoption with FRED API data
- **Data source:** Census BFS via FRED API — worked flawlessly, 204 API calls with one rate-limit pause
- **Key risk:** Outcome measurement mismatch (federal EIN vs state filing where notarization binds)

## Execution
- **What worked:** FRED API is reliable and fast. CS-DiD with monthly data and 22 treated states produced clean pre-trends. The null result is well-powered (MDE ~4%) and consistent across all four outcome types.
- **What didn't:** HonestDiD integration failed (function compatibility issue). Heterogeneity by notarization stringency was promised in the manifest but infeasible without state-level notary density data.
- **Review feedback adopted:** Added limitations paragraph addressing (1) federal/state measurement mismatch, (2) supply-side implementation lags, (3) cross-border contamination bias toward zero, (4) power limitations for modest (1-2%) effects. These were raised by all three reviewers.

## Key Takeaway
Not every intuitive regulatory friction actually binds. In-person notarization sounds like a barrier, but US notary availability is high enough that removing the requirement doesn't move the needle on business formation. The lesson for future idea selection: distinguish between frictions that are *visible* from frictions that are *binding*.
