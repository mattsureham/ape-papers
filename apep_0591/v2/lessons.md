## Discovery
- **Policy chosen:** Erasmus+ programme expansion (budget doubling 2021-2027) — provides large, exogenous variation in student mobility exposure across EU regions
- **Ideas rejected:** None (pinned idea from idea database, idea_0543)
- **Data source:** Zenodo geolocated Erasmus flows (Väisänen et al. 2025) + Eurostat regional outcomes — both fully open, no API keys needed
- **Key risk:** Weak first stage from scale mismatch between Bartik IV levels and endogenous variable

## Execution
- **Critical fix:** Original Bartik IV used level-weighted flows (~2000 students) vs endogenous net_out_rate (mean -0.23) — F<1. Restructured to growth-rate Bartik predicting outflow levels, then scaling by population → F=1,376
- **Instrument choice:** Predicted outflow rate (level-based) vastly outperforms Bartik growth rate as IV — the level specification ensures the instrument and endogenous variable are in the same units
- **Eurostat API quirks:** Column names vary (TIME_PERIOD vs time), age group codes differ across datasets (Y25-34 vs Y25T34), education uses Y25-64 not Y35-64
- **Zenodo data:** Column names come in UPPERCASE — must tolower() immediately after loading
- **RI finding:** p-value = 0.446 from permuting destination shocks. This means the share structure (pre-period bilateral flows) carries much of the identifying variation, not quasi-random destination growth shocks. Honest reporting required.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT R1, Gemini, Codex PASS; GPT R2 FAIL)
- **Referee decisions:** GPT R1 REJECT AND RESUBMIT, GPT R2 MAJOR REVISION, Gemini MINOR REVISION
- **Top criticism:** Country-by-year FE causes the coefficient to collapse to ~0. This reveals that identification relies on cross-country variation, not within-country variation — the most damaging finding for the paper's claims.
- **Surprise feedback:** The formal heterogeneity interaction test (p=0.029) confirms the peripheral differential, but the country-year FE result dominates in terms of importance.
- **What changed in revision:** (1) Systematic claim recalibration — "suggestive" replaces "causal" throughout; (2) Country-year FE added and honestly reported; (3) Two-way clustered SE (p≈0.05) made primary inference; (4) F-stat demoted from 1,376 to t²≈97; (5) Magnitude decomposition added; (6) Treatment timing caveat added; (7) All citation keys fixed; (8) RI framing further toned down.

## v2 Revision Lessons
- **NUTS3 disaggregation:** Zenodo bilateral flows are already at NUTS3 — this enabled within-country identification. 94% of Bartik variance is within-country, first-stage F=60.5 with CxY FE.
- **Table generation:** Panel headers using NA values in kable get flagged by every reviewer. Use \multicolumn in post-processing.
- **Figure-text alignment:** Describing a map when the figure is a scatter plot is an instant FAIL. Always verify captions match descriptive text.
- **Census vs LFS:** Code used LFS averages (2014-16 vs 2021-22) but text said "Census 2011 to 2021." Always verify data pipeline matches paper claims.
- **Sign reversals across specs:** Panel negative, long-difference positive. Frame as "drain vs circulation at different horizons" — don't hide the contradiction.
- **Framing calibration:** All three referees penalize overclaiming. "Suggests" and "is associated with" rather than "demonstrates" when RI p > 0.1.

## Summary
- **Key lesson:** Always run country-by-year FE as a standard robustness check in shift-share designs BEFORE external review. Finding this result before referee submission would have saved significant credibility. The country-year FE test is the most informative single diagnostic for whether a shift-share IV exploits within-country or cross-country variation.
- **Honest reporting matters:** The RI result (p=0.446) and country-year FE attenuation were initially uncomfortable findings, but reporting them transparently and accurately was the right call. Reviewers universally praised the honesty while criticizing the (initial) overly optimistic framing.
- **Process:** Advisor review requires 3+ iterations. Common failures: NA placeholders, text-table mismatches, figure-text mismatches, table notes referencing absent columns. Self-audit before submission saves rounds.
