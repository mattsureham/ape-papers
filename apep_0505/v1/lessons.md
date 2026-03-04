## Discovery
- **Policy chosen:** Council Tax Support (CTS) localization (April 2013) — devolution of council tax relief to 326 English LAs with mandatory pensioner protection creates clean continuous-treatment DiD with built-in placebo
- **Ideas rejected:** Empty Homes Premium (near-universal adoption limits extensive margin variation, reclassification concern), Selective Licensing (treatment dates require FOI, health outcomes already studied by LSHTM), LHA Freeze (dose-response design workable but outcomes harder to match), Benefit Cap (national rollout = no staggered DiD, DV data confounded by recording changes), Flood Re (Garbarino 2024 JRI already published definitive paper)
- **Data source:** DLUHC Council Tax statistics (collection rates, CTS expenditure by LA), HM Land Registry PPD (property prices), data.police.uk archives (crime), NOMIS (claimant counts). All verified working.
- **Key risk:** Minimum payment rate data may need construction from CTS expenditure ratios rather than direct scheme parameter data. Concurrent welfare reforms (benefit cap, bedroom tax, UC rollout) may confound if not properly controlled — pensioner placebo is the key defense.
- **CRITICAL BUG:** NOMIS NM_31_1 API with `age=12` returns 12-year-olds, NOT working-age (16-64). This inflated JSA rates ~8x. Fixed by using `age=0` (total population). Always validate API parameter semantics.

## Review
- **Advisor verdict:** 3 of 4 PASS (Grok, Gemini, Codex PASS; GPT FAIL on 3 internal contradictions)
- **Referee decisions:** GPT MAJOR, Grok MAJOR, Gemini MINOR
- **Top criticism (unanimous):** Post-reform (2017/18) treatment measurement is the Achilles heel. All 3 referees flagged it as the primary identification concern. Cannot be fully resolved without scheme-parameter panel data.
- **GPT advisor fatal errors:** (1) Alternative treatment appendix contradicted main text, (2) JSA denominator "working-age" vs "total population" inconsistency, (3) Table 4 Year FE blank without explanation. All fixed.
- **Surprise feedback:** GPT referee was most thorough — 10 actionable requests in 3 tiers. Grok independently identified same top concern. Gemini was most lenient (MINOR REVISION).
- **What changed in Stage C:** Softened all causal claims ("isolates" → "consistent with isolating"), expanded treatment endogeneity discussion as top limitation, added horse-race multicollinearity limitation, fixed all 3 fatal errors, elevated alternative treatment throughout paper, clarified £4,200 as cumulative not annual.

## Summary
- Horse-race decomposition (WA vs pensioner CTS) is the methodological contribution — reveals sign reversal from pooled positive to WA-specific negative
- Alternative treatment (pre-reform JSA exposure) yielding significant negative effect (β=-0.018, p=0.01) is CRITICAL for credibility — without it, the post-reform treatment measure alone would not support causal claims
- Transparent JSA non-causal labeling is correct given severe pre-trends
- OpenRouter API daily limits are a serious bottleneck for the review pipeline
- Key lesson for future UK papers: scheme-parameter panel data should be sought BEFORE committing to an expenditure-based treatment
