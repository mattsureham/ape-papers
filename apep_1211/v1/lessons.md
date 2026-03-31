## Discovery
- **Idea selected:** idea_1240 — Medicaid nursing home reimbursement rates and the Black-White earnings gap. DDD design with strong leverage from industry comparison.
- **Data source:** QWI race×NAICS 3-digit from Azure (confirmed accessible, 33K obs). Treatment from documented state legislative events.
- **Key risk:** No continuous rate data available — had to use binary treatment coding from legislative events. This limits dose-response analysis.

## Execution
- **What worked:** The DDD design produced a clean, stable result (0.099, robust across all specifications). The compositional upgrading mechanism (rising relative earnings + falling relative employment) emerged as the most interesting finding.
- **What didn't:** The hotel placebo coefficient (0.071) was uncomfortably large — 72% of the main effect — suggesting state-level factors beyond Medicaid reimbursement. The CS event study showed absolute earnings declines, creating a tension with the DDD's relative interpretation that required careful framing.
- **Review feedback adopted:** (1) Rewrote abstract to clarify "relative" language throughout. (2) Added a full paragraph reconciling DDD vs CS estimands. (3) Expanded Discussion to honestly address COVID confound, hours-vs-wages limitation, and placebo concern. (4) Tempered the "wage floor" framing to acknowledge earnings ≠ wages.
