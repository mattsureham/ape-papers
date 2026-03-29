## Discovery
- **Idea selected:** idea_1354 — 14th Finance Commission fiscal devolution, formula-driven cross-state variation, SHRUG nightlights
- **Data source:** SHRUG VIIRS + DMSP nightlights, Census 2011 PCA, FC formula weights (public)
- **Key risk:** Income-distance formula component (50% weight) creates endogeneity with growth trajectories

## Execution
- **What worked:** District-level aggregation handled 8GB RAM constraint well; event study transparently revealed sensor transition; state-specific trends absorb pre-existing convergence
- **What didn't:** Combining DMSP and VIIRS creates a sensor transition confound that dominates the baseline specification; the income-distance targeting means simple DiD is fundamentally compromised for evaluating FC reforms
- **Review feedback adopted:** Added VIIRS-only robustness check (confirming negative trend-adjusted estimate), softened "absence" language to acknowledge nightlights can't capture non-luminous public goods (health, education)
- **Key insight:** Formula-based fiscal policies are inherently hard to evaluate with DiD because targeting criteria predict outcomes through channels other than the transfer itself — the "targeting trap"
