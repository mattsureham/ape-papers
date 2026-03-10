## Discovery
- **Policy chosen:** EU REACH 2018 registration deadline — clear phased design creates natural experiment with tonnage-band variation
- **Ideas rejected:** None (pinned idea from idea database)
- **Data source:** Eurostat SBS (sbs_na_ind_r2, sbs_sc_ind_r2, bd_9ac_l_form_r2) — all free, no API key, reliable coverage across 27 EU countries
- **Key risk:** Pre-treatment convergence trend in employment (CEE catch-up) complicates parallel trends

## Execution
- **Key finding:** Employment (-0.451, p=0.014) significant but enterprises null — "downsizing not exit" narrative
- **Surprise:** Effects concentrate in medium firms (50-249), not micro-firms — supply chain mechanism
- **Size class codes:** Eurostat uses "0-9", "10-19" etc., NOT "LT10" — caused initial data cleaning failure
- **modelsummary broken:** `output="latex"` returns non-character objects — had to hand-craft LaTeX tables with sprintf()
- **Pre-2013 micro-share:** Must use 2008-2012 average for 2013 placebo (not 2014-2017) to avoid post-treatment contamination
- **Event study vs pooled DDD reconciliation:** Year-specific coefficients relative to reference year differ from pooled post-vs-pre comparison — must explain this explicitly in text
- **Employment robustness mandatory:** Advisors require full robustness suite (LOO, alt controls, alt timing, RI) for the headline outcome, not just the null enterprise result

## Review
- **Advisor verdict:** 3 of 4 PASS (after 6 rounds of iteration)
- **External reviews:** GPT-5.4 R1: R&R, GPT-5.4 R2: R&R, Gemini: Major Revision
- **Top criticism:** Employment result does not survive trend adjustment — controlling for differential linear trends by micro-share reduces the estimate from -0.451 to 0.038 (essentially zero)
- **Surprise feedback:** The trend-adjusted specification completely eliminates the employment effect. This was the most honest and important finding of the revision cycle.
- **What changed:** Added trend-adjusted DDD (Table 4), 2008 pre-REACH micro-share, joint F-tests, common sample, drop-2020, short-window specifications. Reframed the entire paper: enterprise null is now the robust finding, employment is "suggestive but fragile." Softened all causal claims. Added Roth (2022), Rambachan & Roth (2023), MacKinnon & Webb (2017). Moved 3 figures to appendix.
- **Key lesson:** ALWAYS run trend-adjusted specifications before making causal claims from DDD designs with visible pre-trends. The pre-trend sensitivity is the most important diagnostic, and it should be run early — not discovered during external review.
