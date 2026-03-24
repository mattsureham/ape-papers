## Discovery
- **Idea selected:** idea_0705 — Swiss MEI referendum as "revealed hostility" signal for immigrant sorting
- **Data source:** BFS PXWeb (population by citizenship) + swissdd R package (referendum results). Both free, no API keys.
- **Key risk:** Pre-existing convergence trends confounding the signal effect. This risk materialized.

## Execution
- **What worked:** Swiss open data infrastructure is excellent — clean municipality-level panels, referendum results via R package when the direct JSON API returned 403. The continuous treatment DiD + RDD complement provided multiple identification angles.
- **What didn't:** The "revealed hostility" hypothesis was overturned by pre-trends. The finding is descriptively interesting (one-directional causality) but the causal claim is limited.
- **Review feedback adopted:** Softened framing from "cheap talk" to "no detectable break"; added limitations on stock vs flow outcomes; acknowledged pre-trends honestly rather than dismissing them; reframed as evidence for one-directional causality in immigration-attitudes relationship.
