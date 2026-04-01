## Discovery
- **Idea selected:** idea_0391 — Australia's carbon tax intro+repeal as symmetric natural experiment (from random draw of 10)
- **Data source:** ABS Cat 6291.0.55.001 via readabs R package — API initially tricky (SDMX endpoint lacks industry detail; needed readabs for Table 5)
- **Key risk:** Only 8 geographic clusters; Division D too broad (includes water/waste)

## Execution
- **What worked:** The symmetric on-off design is genuinely unique in the carbon pricing literature. The continuous treatment (coal share 0-92%) maximizes identifying variation from few clusters. The null is robust across specifications, placebos, and RI.
- **What didn't:** Cannot isolate electricity generation from the broader ANZSIC Division D. ABS 3-digit industry data not available at state level in LFS. This attenuates any true effect toward zero and limits the mechanism decomposition (coal job loss vs renewables job gain) that would have been the paper's strongest contribution.
- **Review feedback adopted:** (1) Added power/MDE discussion bounding detectable effects; (2) Reframed state-trend specification as bounding exercise rather than dismissing it; (3) Softened "job-killing" rhetoric to acknowledge moderate effects can't be excluded; (4) Added option-value-of-repeal mechanism for why firms didn't fire workers; (5) Addressed Division D measurement error transparently.
