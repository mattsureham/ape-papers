## Discovery
- **Idea selected:** idea_1426 — AAA cotton acreage reduction and Black sharecropper children. Chosen for strong historical natural experiment with massive individual-level panel data (236K observations) and innovative within-family identification.
- **Data source:** MLP 1930-1940-1950 panel on Azure — worked perfectly, exact counts matched smoke test predictions (236,773 Black farm children, 51,022 sibling households).
- **Key risk:** USDA NASS API failed (URL formatting issue), so fell back to Black farm population share as cotton intensity proxy. This was the main reviewer concern.

## Execution
- **What worked:** The sibling FE design produced a clear, surprising result — education INCREASED for school-age children in high-AAA counties, flipping the expected sign. The temporal pattern (negative occ score in 1940, positive in 1950) confirmed the mechanism cleanly.
- **What didn't:** IPUMS EDUC coding required careful handling (categorical 0-11, not years). Initial diagnostics failed validation (n_pre mismatch for cross-sectional design). USDA NASS API URL issue blocked the ideal treatment variable.
- **Review feedback adopted:** Both reviewers flagged the treatment proxy issue and the need to temper the "displacement dividend" framing. Added treatment validity subsection and reframed as "mitigating channel" rather than "net benefit."
