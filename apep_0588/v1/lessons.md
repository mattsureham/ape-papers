## Discovery
- **Policy chosen:** 2022 Russian gas cutoff — massive pre-determined cross-country variation in gas dependence (0-75%), first-order mortality outcome, no causal study exists
- **Ideas rejected:** Geo-blocking DDD (HICP too aggregate for online price mechanism), PSD2 (small sample, 368 obs), roaming abolition (simultaneous treatment, no staggered variation), antimicrobial ban (noisy agricultural outcomes, 31 country-years)
- **Data source:** Eurostat weekly mortality (demo_r_mwk_ts, demo_r_mwk_05) + HICP energy prices + gas import data — all free API, no keys needed
- **Key risk:** Only 20 country clusters; will need wild cluster bootstrap and randomization inference. Age-disaggregated weekly data available for only ~8 countries — may limit age-gradient placebo to subsample or annual data.

## Review
- **Advisor verdict:** 3 of 4 PASS (after 8 rounds — extensive consistency fixes required)
- **Top criticism:** Fiscal mechanism not identified by design — cannot attribute null to policy vs weather vs conservation
- **Surprise feedback:** "Precise zero" language flagged as overclaiming even by sympathetic reviewers; 95% CI of [-0.36, 1.28] is not trivially narrow
- **What changed:** Reframed fiscal claims as "one plausible explanation among several"; replaced "precise zero" with "no statistically detectable increase"; added explicit 95% CIs; softened parallel trends language; acknowledged summer placebo near-significance; clarified age analysis uses raw counts not rates
- **Key lesson:** LLM advisors are extraordinarily sensitive to internal consistency — every number, definition, and sample description must match exactly across abstract, text, tables, notes, and appendices. Fix consistency issues BEFORE running advisor review to save rounds.
