## Discovery
- **Policy chosen:** Japan's 2019 dual-rate consumption tax (8% takeout vs 10% eat-in) — globally unique natural experiment where identical products face different tax rates based on consumption location
- **Ideas rejected:** None (pinned idea from database)
- **Data source:** Japan FIES via e-Stat — monthly household expenditure by commodity class; ~8,000 households/month. Secondary: Japan CPI by commodity group
- **Key risk:** COVID-19 contamination starting February 2020 limits clean post-treatment window to 5 months; must carefully separate tax-driven from pandemic-driven switching

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT R1 PASS, GPT R2 PASS, Codex PASS; Gemini FAIL on interpretive concerns)
- **Referee verdicts:** Gemini MINOR, GPT R1 MAJOR, GPT R2 REJECT-RESUBMIT
- **Top criticism:** HC1 SEs inappropriate for serially correlated aggregate monthly time series; must use Newey-West. This is correct — NW SEs are ~3x larger for the full-sample estimate, making it non-significant.
- **Surprise feedback:** Both GPT referees flagged that "same product, same store" framing is too strong for aggregate CPI categories. Fair point — CPI categories are broader than the legal tax boundary.
- **What changed:** (1) Switched to Newey-West SEs as primary; (2) Added formal test of full-pass-through benchmark H0:β=0.0183; (3) Added full placebo-in-time distribution (Fig 7); (4) Reframed as "comparative ITS on aggregate CPI" rather than standard DiD; (5) Toned down all claims from "complete" to "consistent with near-complete"; (6) Expanded limitations section; (7) Added pre-COVID DDD; (8) Added Bertrand et al. (2004) citation
