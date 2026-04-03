## Discovery
- **Idea selected:** idea_0449 — Groningen earthquake/housing price recovery. Reframed from political economy of regulatory pace (N=7 decisions, too small) to spatial DiD on housing prices (292 municipalities × 27 years).
- **Data source:** CBS 83625NED (housing prices), KNMI FDSN (earthquakes), NAM/Rijksoverheid (production). CBS OData had API issues — ODataApi doesn't support $skip pagination, had to use ODataFeed endpoint.
- **Key risk:** Pre-existing Randstad-vs-periphery divergence confounds distance-based treatment.

## Execution
- **What worked:** Data collection from three Dutch public APIs yielded a clean panel. The physical production-earthquake mechanism is real and documented. The descriptive pattern of price recovery is visible.
- **What didn't:** Pre-trends fail decisively (p<0.001). Placebo epicenter test is devastating (45% produce similar effects). The continuous inverse-distance treatment conflates economic geography with earthquake exposure. Identification is not clean enough for causal claims.
- **Review feedback adopted:** Reframed as descriptive case study (all three reviewers flagged causal overclaiming). Fixed SDE scaling (SDEs were initially 4-7 SD, corrected to ~0.03 after proper continuous-treatment standardization). Added magnitude interpretation for concrete distance comparisons. Fixed municipality count discrepancy in data section.
- **Lesson for future papers:** When treatment intensity correlates with an underlying spatial gradient (peripheral vs. core), the standard spatial DiD breaks down. Need either local comparison groups (nearby untreated municipalities with similar characteristics) or very different identification strategies. The Groningen case would benefit from within-province variation or damage-claim-based treatment rather than distance-to-epicenter.
