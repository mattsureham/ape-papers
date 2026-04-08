## Discovery
- **Idea selected:** idea_0560 — UK pension auto-enrollment step-up, testing mandate-tax hypothesis
- **Data source:** NOMIS API (ASHE earnings + UK Business Counts) — worked perfectly, fast, no auth needed
- **Key risk:** Aggregate LA-level identification can't isolate pension effect from confounding macro shocks

## Execution
- **What worked:** Employment-weighted firm-size shares gave meaningful cross-LA variation (SD=0.097); NOMIS API was reliable and fast; placebo test supported parallel trends within pre-period
- **What didn't:** Event study pre-trends are noisy (F-test rejects); the positive effect concentrates in 2022-2023 (post-COVID recovery), not immediately after April 2019; can't validate that small-firm share actually proxies for binding-minimum exposure without ASHE pension contribution microdata
- **Review feedback adopted:** Tempered all causal claims; reframed as suggestive evidence; noted timing inconsistency prominently; acknowledged ecological fallacy limitation
