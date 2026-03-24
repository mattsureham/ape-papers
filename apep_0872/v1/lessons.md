## Discovery
- **Idea selected:** idea_1277 — Hungary's 2010 bank levy, the largest in EU history. Chosen for enormous effect size, sharp treatment timing, and built-in policy reversals (FGS 2013, levy halving 2016).
- **Data source:** ECB BSI (monthly NFC loans) and World Bank (annual credit/GDP). ECB SDMX API required broad query patterns for non-euro countries; specific key patterns returned 404s.
- **Key risk:** N=1 treated country. Tournament lessons repeatedly warn against designs with very few treated units.

## Execution
- **What worked:** The data clearly showed a dramatic divergence — Hungary flat while CZ/PL grew 80%+. Monthly frequency gave a clean event study. The three-period specification (Pre/Levy/FGS) was the most informative decomposition.
- **What didn't:** Slovakia's ECB BSI data was a subcategory (186-571 EUR mn), not the aggregate, and had to be dropped. The augmented SCM's "joint null" p-value was uninformative (p=1) despite strongly significant per-period estimates — conformal inference with 3 donors is underpowered for joint tests.
- **Review feedback adopted:** Added discussion of FX lending restrictions as a key confounder (Qwen reviewer's strongest point). Reframed FGS from "failed" to "insufficient to fully offset." Expanded limitations to four caveats including sovereign risk and concurrent regulatory changes. Made explicit that the paper is a well-identified case study, not a definitive causal estimate.
- **Review feedback deferred:** Bank-level analysis exploiting progressive rate structure (requires Bankscope/MNB data not available via API). Interest rate pass-through data from ECB MIR series. CDS spread controls. Wild bootstrap with few clusters.
