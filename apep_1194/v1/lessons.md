## Discovery
- **Idea selected:** idea_2044 — PTC has never been causally evaluated despite $14B investment; 69 railroads with staggered adoption provide clean variation
- **Data source:** FRA Form 54 via Socrata API — no key needed, 224K records spanning 1975-2026, seamless fetch
- **Key risk:** Treatment identified from accident-level adjunct codes rather than railroad-level implementation milestones; creates potential measurement error

## Execution
- **What worked:** Built-in cause-code placebo (human-factor vs non-human-factor) is a genuinely powerful design feature; Callaway-Sant'Anna handled well with 49 treated / 114 never-treated; balanced panel construction straightforward
- **What didn't:** `did` package requires `first_treat` as double not integer — Inf truncation silently drops never-treated group if column is integer; cost several minutes debugging
- **Key finding:** Precise null on human-factor accident frequency masks heterogeneous effects — Class I railroads show large negative effect while non-Class I shows positive
- **Review feedback adopted:** Added heterogeneity subsection (Class I vs non-Class I), cost-benefit break-even calculation, strengthened limitations on measurement error and exposure normalization
