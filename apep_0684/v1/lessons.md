## Discovery
- **Idea selected:** idea_0354 — MATS coal compliance bifurcation (managed industrial decline, first-order stakes)
- **Data source:** EIA API v2 (facility-fuel, operating-generator-capacity, retail-sales) — EIA website was down for bulk files but API worked perfectly
- **Key risk:** Endogeneity of state-level retirement shares to concurrent energy market shocks

## Execution
- **What worked:** The regulated/deregulated mechanism split emerged cleanly and became the paper's distinctive contribution. Coal share control strengthened the main estimate (from 0.081 to 0.130), providing strong evidence against the main confounding concern. Event study pre-trends were perfectly clean.
- **What didn't:** 2SLS with state-level heat rate as instrument was too weak (corr = -0.12). Plant-level variation in heat rate averages out at the state level — need finer geographic granularity (county or plant-level) for a credible IV strategy.
- **Review feedback adopted:** Added coal share × post control as preferred specification; narrowed claims from "who pays" broadly to retail price incidence specifically; strengthened limitations discussion. Did NOT adopt county-level employment analysis (data too heavy for V1) or formal 2SLS (weak instrument).
