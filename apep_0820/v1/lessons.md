## Discovery
- **Idea selected:** idea_1774 — Gaussian plume IV for pollution and test scores. Selected because tournament lessons reward simulated instruments with deep data.
- **Data source:** EPA ECHO (facilities), EdFacts (test scores), ASOS (wind), AQS (monitors). CAMPD and TRI APIs were blocked/down; pivoted to ECHO two-step API.
- **Key risk:** Without per-facility emissions data, the instrument captures dispersion geometry rather than actual pollution concentrations.

## Execution
- **What worked:** The ECHO two-step API provided 35,598 facility locations. Wind roses from ASOS successfully created year-to-year variation. The Gaussian plume computation was straightforward.
- **What didn't:** CAMPD API returned 403 (needs API key now). TRI Envirofacts returned 404. SEDA Stanford server returned empty files. Had to pivot to EdFacts proficiency rates (coarser than SEDA).
- **Main result:** -0.218 SD effect (SE=0.108, t=-2.03). Attenuates to -0.038 with state×year FE.
- **Review feedback adopted:** Softened causal language to "reduced-form" and "associated with"; acknowledged state×year attenuation as a genuine limitation rather than explained-away feature.
