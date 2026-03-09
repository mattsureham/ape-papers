## Discovery
- **Policy chosen:** Oil shock × aid interaction in Nigeria — appealing because the 2008 crash is exogenous, aid data is geocoded, and the null is publishable
- **Ideas rejected:** Cross-country aid-conflict (too macro, weak identification), Nigerian procurement transparency (data quality concerns), health aid impact (too many existing papers)
- **Data source:** AidData AIMS v1.3.2 (geocoded), UCDP GED v24.1 (conflict), FRED Brent crude — all fetched successfully
- **Key risk:** Single national shock design vulnerable to state-specific post-2008 confounders (Boko Haram)

## Review
- **Advisor verdict:** 4 of 4 PASS (after 8 rounds — agriculture t=51 and CI consistency were main blockers)
- **Top criticism:** Identification relies on single national shock + endogenous cross-sectional aid exposure; design cannot isolate "buffering" from any post-2008 divergence correlated with aid
- **Surprise feedback:** Both GPT reviewers independently recommended building triple-diff around FAAC fiscal exposure heterogeneity — a genuinely good idea that the current data cannot support
- **What changed:** Added wild cluster bootstrap, exclude-northeast, zone×post FE; softened all "well-powered null" and causal claims; reported pre-trend F-test; fixed SDE classifications

## Summary
- **Key lesson:** Null result papers with a single shock + cross-sectional treatment face an inherent tension: the null could reflect genuine absence of effect OR insufficient identifying variation. Future null-result papers should invest more in demonstrating the design can detect effects of relevant magnitude.
- **What worked:** Battery of robustness checks (RI, placebo, LOO, PPML, alternative dates, WCB, exclude-NE, zone×post) made the null credible.
- **What didn't work:** Agriculture sector heterogeneity caused multiple advisor review failures due to t=51 collinearity artifact. Should have excluded it from the start.
- **Time sinks:** Advisor review loop (8 rounds) — driven by cascading text-table inconsistencies. Fix: enforce a single source of truth for all reported numbers.
