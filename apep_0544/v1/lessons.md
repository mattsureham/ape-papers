## Discovery
- **Policy chosen:** Russia's 2022 gas cutoff to Europe — the largest energy supply disruption in European history, with rich country x sector variation in exposure. Chosen for maximum information gain: every European energy policy since 2022 was made without a formal causal estimate.
- **Ideas rejected:** Immigration judge IV (idea_0012) — strong design but Gemini gave SKIP due to complex EOIR data linkage. Red Flag Laws (idea_0009) — all three models gave SKIP due to power concerns with CDC suppressed cells.
- **Data source:** Eurostat public APIs (STS_INPR_M, NRG_TI_GAS, NRG_BAL_C) — all confirmed accessible, no authentication. 12.7M observations.
- **Key risk:** COVID-19 created noisy 2020-2021 period. Using Jan 2018 start date and triple FE to absorb this. Government energy subsidies attenuate effects (conservative bias).

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT R1 PASS, GPT R2 PASS, Gemini FAIL, Codex PASS)
- **Top criticism:** All 3 referees flagged severe over-claiming — "first causal evidence," "lower bound," "hysteresis" language far too strong for β=-0.231, t=-0.54. This was the paper's single biggest weakness.
- **Surprise feedback:** March 2019 placebo (-0.345 > main -0.231) was flagged by all 3 as a genuine design concern, not just a COVID artifact. This is a real limitation that I initially underweighted.
- **What changed:** Complete prose recalibration of abstract, intro, results, discussion, conclusion. Removed all "lower bound" claims (3 instances). Reframed as "reduced-form evidence." Added shift-share citations (Goldsmith-Pinkham 2020, Borusyak 2022). Expanded Hungary LOO discussion. New "estimand interpretation" and "gas intensity as proxy" paragraphs addressing the identification clarity concern.

## Summary
- **Key lesson:** With 23 clusters and t=-0.54, the paper's value is in the design and the honest reporting of imprecision, not in the point estimate. Over-claiming null results is the #1 reviewer complaint. Lead with what you know (the design is credible) and be honest about what you don't (the effect size).
- **Design lesson:** The triple-FE structure is right for this question but underpowered with 23 countries. 10 distinct gas intensity values (from NRG_BAL mapping) further limits variation. Future work needs NUTS-2 or firm-level data.
- **Process lesson:** 6 rounds of advisor review were needed. Most fixes were factual errors (Ireland not in sample, Hungary LOO value wrong, event study monthly not quarterly). Always verify claims against actual data before writing.
