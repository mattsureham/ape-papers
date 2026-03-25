## Discovery
- **Idea selected:** idea_0515 — EU Late Payment Directive triple-diff with firm size class. Chose over Poland 500+ (already covered by apep_0841), Swiss MuKEn 2014 (pre-period data gap), and India e-NAM (API reliability concerns).
- **Data source:** Eurostat bd_9bd_sz_cl_r2 — massive (19M rows raw), excellent coverage (94% non-missing for death rate). Birth rate indicator (V97130) had almost no data — had to drop entirely.
- **Key risk:** Payment culture intensity relies on Intrum hand-coded country averages rather than API-accessible data. This is the weakest link in the chain.

## Execution
- **What worked:** Triple-diff design with saturated FE (country×size, country×year, size×year) is clean and interpretable. Leave-one-out gives tight range [0.38, 0.69]. The "invoice gap" framing — rights without enforcement — is a crisp economic object.
- **What didn't:** Birth rate data was entirely missing, limiting the outcome set to death rate and survival rate. The survival rate estimates are too imprecise to draw conclusions. Pre-trends are noisy in early years (2004-2005).
- **Review feedback adopted:** Fixed transposition date factual error (GPT-5.4 caught it). Removed NaN birth rate from Table 1 (Gemini caught it). Clarified cohort-based survival rate definition. Toned down causal language from "directive failed" to "no evidence of help." Added note about 2023 proposed regulation. Reviewers wanted sectoral heterogeneity and enforcement proxies — infeasible in V1 but flagged for potential revision.
