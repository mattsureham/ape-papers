## Discovery
- **Idea selected:** idea_1477 — First causal test of employer credit check bans on racial hiring gaps. Strong because: vivid mechanism (credit screening is racially disparate), clean DDD design with within-sector placebo, massive QWI admin data, untested theoretical model (Cortes et al. 2021).
- **Data source:** QWI race×industry panels from Azure Blob Storage — 835K rows fetched in under a minute. Azure connection string truncation by bash `source` cost 15 minutes debugging (semicolons in value).
- **Key risk:** TWFE vs CS divergence. The CS estimator struggles with this data because QWI suppression creates unbalanced panels and small treatment cohorts (Hawaii 2009 = 4 counties).

## Execution
- **What worked:** The DDD design is genuinely clean. Agriculture placebo (-0.024, n.s.) and White worker placebo (0.020, n.s.) are both precise zeros — exactly as theory predicts. Results stable across 5 robustness checks. The "screening dividend" framing gives the paper a conceptual hook beyond "we estimate the effect of X."
- **What didn't:** CS estimator on the racial gap is noisy and null. The divergence from TWFE is real and I can't fully resolve it in a V1 paper. Future revision should explore stacked DDD or de Chaisemartin-D'Haultfoeuille.
- **Review feedback adopted:** (1) Translated magnitude into approximate hires (~3-4 per county-quarter). (2) Addressed the finance exemption paradox (non-exempt positions are the affected margin). (3) Added explicit defense of TWFE DDD citing Goodman-Bacon on negative weighting.
