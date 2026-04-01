## Discovery
- **Idea selected:** idea_0940 — Swiss franc shock and municipal structural transformation. Clean exogenous shock, large N (2,053 municipalities), excellent data access.
- **Data source:** BFS STATENT via PXWeb API — worked perfectly, no auth needed. Chunked requests (300 municipalities per call) with 0.3s delay.
- **Key risk:** Pre-trends in manufacturing-heavy municipalities and construction contamination in secondary sector measure.

## Execution
- **What worked:** The event study reveals a dramatic break-in-trend at 2015 — pre-shock slope of +0.9pp/year reverses to -1.3pp/year. Municipality-specific linear trend control barely changes the coefficient (-0.058 vs -0.059). The asymmetric timing of destruction vs reallocation is the paper's strongest finding.
- **What didn't:** The secondary sector includes construction (non-tradable), which dilutes the treatment measure. STATENT only goes back to 2011, giving only 4 pre-periods (validator requires 5). Could not access municipal-level NOGA 2-digit data.
- **Review feedback adopted:** Reframed identification as break-in-trend (not clean parallel trends). Added explicit discussion of construction contamination as attenuation bias. Softened claims from "permanent" to "persistent." Reframed placebo honestly. Emphasized level outcomes alongside shares.
