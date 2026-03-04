## Discovery
- **Policy chosen:** UAE kafala reform (Federal Decree-Law 33/2021, effective Feb 2022) — first causal evaluation of any kafala reform worldwide; extreme monopsony setting
- **Ideas rejected:** (1) Weekend shift — too financial/niche, not labor economics; (2) Emiratization quotas — incremental over Cortes et al. 2023 on Saudi Nitaqat; (3) Remittances — annual KNOMAD data is model-based/imputed, too few post-periods; (4) Cross-GCC comparison — only 6 countries, too few clusters
- **Data source:** Dubai Financial Market (DFM) daily stock returns via Yahoo Finance; ~45 firms with data back to 2019
- **Key risk:** Small N (45 firms) limits power; sector classification as proxy for monopsony exposure is coarse; Emiratisation bundling confounds interpretation

## Review
- **Advisor verdict:** 3 of 4 PASS (Grok, Gemini, Codex passed; GPT failed) — took 4 rounds to pass
- **Top criticism:** Benchmark contamination — CARs subtract a market index built from treated/control firms. The stacked DiD sidesteps this but main CAR specs are vulnerable.
- **Surprise feedback:** GPT rated MAJOR REVISION while Grok/Gemini gave MINOR REVISION — divergence centered on Emiratisation bundling and benchmark contamination severity
- **What changed:** (1) Reframed estimand from "bound on kafala rents" to "differential valuation effect of reform package"; (2) Expanded Emiratisation from limitation to central identification challenge with back-of-envelope costs; (3) Added full Limitations section (Section 8) covering benchmark contamination, thin trading, cross-sectional correlation, RI structure, external validity, free zone heterogeneity; (4) Added 30-day MA smoothing to Figure 7; (5) Added vivid firm examples (Emaar vs Emirates NBD); (6) Added citations (Sokolova & Sorensen, Cameron et al., Kolari & Pynnonen, ILO Qatar)

## Summary
- **Key lesson:** When the "control group" faces its own simultaneous policy shock (Emiratisation quotas), the DiD is no longer clean — must either de-bundle or reframe the estimand as net effect
- **Methodological lesson:** Sample-constructed market indices contaminate CARs — use official exchange indices or benchmark-free approaches (stacked DiD with date FE)
- **Writing lesson:** Calibrated claims earn more credibility than bold claims. "Informative bound under stated assumptions" is stronger science than "we reject large monopsony rents"
