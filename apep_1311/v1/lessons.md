## Discovery
- **Idea selected:** idea_1947 — Colombia SECOP II e-procurement staggered rollout
- **Data source:** datos.gov.co Socrata API (SECOP Integrado + SECOP II Procesos) — slow for large GROUP BY queries, but simple filter queries work at ~50K records per 15s
- **Key risk:** Entity identifiers differ across SECOP I and SECOP II platforms, preventing within-entity tracking

## Execution
- **What worked:** The SECOP II process-level data (1.97M records) is excellent — bidder counts, award values, modalities. The cross-sectional early vs late adopter comparison yielded the strongest result (-6.7pp single-bidder rate for early adopters).
- **What didn't:** The entity-level DiD that the idea promised was impossible due to platform-specific entity codes. Had to pivot to department-level (38 units) which sacrificed power. The intensity specification suffered from mechanical linkage between platform choice and competitive modality.
- **Data engineering lesson:** Socrata API formats large offsets as scientific notation in R — must use `format(offset, scientific=FALSE)`. Also, fetching 10M+ records requires multiple batched pulls with date-range filters.
- **Review feedback adopted:** Acknowledged tautological concern with intensity specification; reframed binary specification as primary; expanded limitations section to discuss entity-identifier mismatch, mechanical linkage, and inability to observe bidder identities on SECOP I.
