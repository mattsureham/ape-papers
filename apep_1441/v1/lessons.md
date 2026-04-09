# Lessons: apep_1441/v1

## Discovery
- Swiss BFS PXWeb API requires German-language endpoint (`/api/v1/de/`); English returns 400.
- Must navigate directory tree to find actual `.px` data files — table IDs are directories, not endpoints.
- Large queries (86 sectors x 27 cantons x 13 years x 7 units) get 403. Split by observation unit.
- JSON-stat2 format uses NULL for suppressed cells — need explicit NULL→NA handling.

## Review
- All three reviewers converged on wanting event study plots — not feasible in V1 (zero figures). A V2 should lead with this.
- "Precisely estimated null" was flagged as overstated given CI width [-2.5%, +1.9%]. "Bounded null" is more honest.
- DDD interpretation needs explicit sum-of-coefficients (Treated×Post + DDD = net effect) to avoid confusion.
- Reviewers wanted dose-response by canton — reasonable for V2 but infeasible with 5 treated units in V1.

## Summary
BFS PXWeb API debugging took ~30 min (6+ attempts). Analysis and writing were straightforward once data was in hand. The CS vs TWFE divergence (-0.3% vs -2.9%) is the paper's strongest contribution — methodological lesson wrapped in a policy finding. Total time: ~90 minutes idea-to-publish.
