## Discovery
- **Idea selected:** idea_0328 — Italy's sequential labor shocks (Fornero + RdC). Selected for unique natural experiment, first-order stakes, and Eurostat data accessibility.
- **Data source:** Eurostat NUTS2 panel (lfst_r_lfe2emprt, edat_lfse_22) + INPS RdC administrative data. Eurostat API worked perfectly with the `eurostat` R package (note: column is `TIME_PERIOD`, not `time`).
- **Key risk:** High treatment collinearity (r = -0.884). The idea manifest claimed "nearly orthogonal" — completely wrong. This is the defining constraint of the design.

## Execution
- **What worked:** The "accidental hedge" reframing turned a null finding into the central contribution. Geographic mismatch IS the story. Clean event study for Fornero on youth employment with strong pre-trends. Placebo outcomes (45-54, 55-64 employment) passed cleanly.
- **What didn't:** Wild cluster bootstrap failed with `fwildclusterboot` — appears to be a compatibility issue with the standardized interaction terms. Permutation inference worked as substitute. RdC causal claim is compromised by COVID confound.
- **Review feedback adopted:** Softened RdC causal language, added explicit collinearity limitation in empirical strategy, expanded limitations section, referenced event study pre-trends. Both reviewers identified the same core issues (collinearity + COVID), which validates the concern.
