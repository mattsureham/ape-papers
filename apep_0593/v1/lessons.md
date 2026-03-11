## Discovery
- **Policy chosen:** EU Roam Like at Home (2017) — universal, salient, simultaneous treatment with clear spatial variation in exposure
- **Ideas rejected:** F-Gas (small N=12 countries), Geo-Blocking (effects likely tiny), PAD (only 120 Findex obs), PSD2 (too many confounders)
- **Data source:** Eurostat tour_occ_nin2 (8,135+ obs, NUTS2 tourism nights) — no API key needed
- **Key risk:** Pre-trends in border vs interior regions; COVID contaminating post-2019 window

## Review
- **Advisor verdict:** 4 of 4 PASS (after 8 rounds of fixes)
- **Top criticism:** Treatment-outcome mismatch — "foreign nights" includes non-EU visitors, attenuating the treated margin. All 3 referees flagged this.
- **Surprise feedback:** GPT R2 caught that the text said SE increases under country×year FE when it actually decreases — an empirical claim that contradicted the table.
- **What changed:** (1) Title and abstract recalibrated to match observable estimand (accommodation nights, not "tourism"). (2) Wild cluster bootstrap p-values added (all confirm null). (3) Exclude-2017, common-sample, and population-weighted robustness checks added. (4) SE text inconsistency fixed. (5) Mechanisms reframed as "interpretations consistent with the null." (6) Prose polish per Gemini suggestions.

## Summary
- **Key lesson:** For null-result papers, claim calibration is the #1 review concern. Match claims precisely to what the data and design can identify — never overgeneralize to "cross-border tourism" when you measure "foreign accommodation nights in border regions."
- **WCB implementation note:** fwildclusterboot v0.14 has a bug with feols objects. Workaround: use fixest::demean() for FWL projection, then lm() for boottest().
- **Advisor review bottleneck:** 8 rounds to pass advisor review, mostly due to (a) kable double-prefix bug, (b) missing heterogeneity table, (c) sample-size documentation confusion. Lesson: get table generation right in R code from the start — manual .tex patches get overwritten.
