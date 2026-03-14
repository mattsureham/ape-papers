## Discovery
- **Idea selected:** idea_0897 — IR35 off-payroll reforms and PSC dissolution. Chosen for vivid headline fact (-26% IT companies), clean natural placebo (COVID delay), and simple data (NOMIS API).
- **Data source:** NOMIS UK Business Counts (NM_142_1) — required discovering internal industry codes; guest API access has 25K row limit but API key raises to 100K.
- **Key risk:** Few-cluster inference (only 8 sectors, 4 treated) makes formal significance borderline.

## Execution
- **What worked:** The COVID placebo test (2020 delay) is a beautiful validation — effect appears precisely when reform takes effect, not during delay year. Organizational form decomposition (companies vs sole props vs total) tells a clear mechanism story.
- **What didn't:** Sector-level treatment means 29,232 observations are really 72 effective cells. LA×year FE absorbs local shocks but doesn't generate independent treatment variation. GPT-5.4 reviewer correctly identified this as the fundamental limitation.
- **Review feedback adopted:** Clarified 43,000 raw vs 19.3% causal distinction, added joint pre-trend test, cited Goodman-Bacon (2021) on few-cluster inference, added discussion of worker-per-company ratio.
- **For V2:** Exploit within-sector variation using pre-reform PSC intensity, client-size composition (small firm exemption), and public-sector dependence (2017 reform). Build continuous exposure measure instead of binary treatment.
