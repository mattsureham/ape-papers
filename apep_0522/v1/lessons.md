## Discovery
- **Policy chosen:** Flood Re reinsurance scheme (UK, April 2016) — Clear treatment date, affects all high-risk residential properties built before 2009, rich variation by flood risk band and property type. Novel: no existing causal study of Flood Re's effect on property values.
- **Ideas rejected:** (1) Universal Credit rollout — too many confounding simultaneous welfare reforms; (2) Plastic bag charge — effect likely too small for property-level analysis; (3) Clean Air Zones — too recent, limited post-treatment data; (4) Stamp duty holiday — already well-studied by Best & Kleven (2018).
- **Data source:** HM Land Registry Price Paid Data (universe of English residential transactions, free download) + Environment Agency flood risk postcode classifications. No API keys needed. Postcodes.io geocoding was initially planned but eliminated as impractical (~700K unique postcodes); replaced with postcode-prefix England filtering and direct postcode merge.
- **Key risk:** EA flood risk data is cross-sectional — we cannot observe changes in flood risk classification over time. This means treatment is time-invariant, which simplifies DiD but prevents studying how risk reclassification affects prices.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT FAIL, Grok PASS, Gemini PASS, Codex PASS)
- **Top criticism:** Pre-existing differential trends violate parallel trends assumption; placebo tests at 2012 and 2014 yield significant positive coefficients
- **Surprise feedback:** Trend-adjusted DiD yields a LARGER coefficient (0.045 vs 0.021), suggesting pre-trends mask rather than explain the treatment effect
- **What changed:** Added trend-adjusted specification; reframed DDD as suggestive; made dose-response the primary identification; clarified control group includes Low/VeryLow/None; fixed table coefficient labels; improved prose per Gemini review

## Summary
- **Policy:** Flood Re (UK government reinsurance, 2016)
- **Key finding:** 2-3% DiD effect, 3.4% dose-response for High-risk only
- **Main limitation:** Pre-existing differential trends compromise baseline DiD identification
- **Strongest evidence:** Dose-response gradient (only High-risk significant)
- **Data:** 12.4M Land Registry transactions × EA flood risk classifications
