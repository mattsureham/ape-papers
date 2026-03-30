## Discovery
- **Idea selected:** idea_0719 — EU directive transposition delay and firm entry. Chosen for genuine novelty (no prior paper tests economic consequences of delay), strong data availability (CELLAR + Eurostat, no API keys), and clean identification (within-directive cross-country variation).
- **Data source:** CELLAR SPARQL (178K NIMs) + Eurostat bd_enace2_r3 — the eurlex R package NIM query is broken; required custom SPARQL pagination. Title queries for sector mapping fail with URI length limits.
- **Key risk:** Directive-to-sector mapping is coarse (broad NACE sections), attenuating the effect and creating noise.

## Execution
- **What worked:** The "implementation gap" framing is clean and memorable. TWFE with cs + year FE is the right specification given 3 sectors. Wild cluster bootstrap confirms significance with 20 clusters. The null on active enterprises is a strong mechanism check.
- **What didn't:** CELLAR data quality is uneven — many "not transposed" entries are missing data, not real limbo. C-S estimator contradicts TWFE sign, driven by composition (newer EU members have both faster growth and more delays). Three-way FE (cs + country×year + sector×year) is infeasible with only 3 sectors.
- **Review feedback adopted:** Softened causal claims given C-S discrepancy. Added magnitude contextualization (Klapper et al. comparison). Improved C-S discussion with event study evidence on differential pre-trends.
