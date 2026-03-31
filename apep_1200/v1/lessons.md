## Discovery
- **Idea selected:** idea_1310 — Swiss Mass Immigration Initiative close-vote RDD on municipal demographics. Second attempt after idea_0057 (Malawi SCTP) failed due to insufficient DHS pre-periods.
- **Data source:** swissdd R package (GitHub) for vote data + BFS PXWeb API for municipal population by citizenship. All open, no credentials needed.
- **Key risk:** The 50% threshold carries no municipal-level policy consequence, making the discontinuity assumption fundamentally different from standard close-election RDDs.

## Execution
- **What worked:** Swiss open data ecosystem is excellent. swissdd provided 2,114 municipalities instantly. BFS PXWeb (via pxweb R package) delivered 10 years × 2,134 municipalities × 2 citizenship categories. McCrary test (p=0.40) and covariate balance all clean. The paper's honest framing of a marginally significant result with appropriate caveats.
- **What didn't:** The httr-based PXWeb query kept returning 400 errors — the pxweb R package was needed to handle the API encoding correctly. Placebo cutoffs at 40% and 45% produced effects, suggesting a gradient rather than a sharp discontinuity. Pre-treatment placebo showed some baseline differential (p=0.103).
- **Review feedback adopted:** (1) Added footnote acknowledging scope narrowing from manifest's cross-border worker angle, (2) strengthened estimand description as reduced-form sentiment revelation, (3) added paragraph on gradient interpretation and foreign-share decomposition limitation.
