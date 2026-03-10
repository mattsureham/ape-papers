## Discovery
- **Policy chosen:** EU Industrial Emissions Directive BAT conclusions — staggered rollout of 13 sector-specific technology standards (2012-2019) across all EU member states
- **Ideas rejected:** Idea came from persistent database (idea_0531), pre-vetted; no inline discovery needed
- **Data source:** Eurostat air emissions accounts (env_ac_ainah_r2) — pivoted from E-PRTR facility-level data after discovering that DiscoData only had 2017-2018 coverage with poor activity code metadata
- **Key risk:** Sector-level aggregation dilutes treatment effect if most facilities were already compliant; only 7 BAT sector clusters limits statistical power

## Execution
- **Data pivot was critical:** E-PRTR facility data (629K records) had insufficient time coverage for staggered DiD. Eurostat sector-level data provided 25-year panels across 30 countries.
- **Null result emerged cleanly:** All three estimators (TWFE, Sun-Abraham, CS-DiD) show null effects on all pollutants. CO2 placebo validates design. RI p=0.50.
- **Anticipation finding:** Marginally significant negative effect at adoption date (-0.075, p=0.087) vs null at compliance deadline — suggests front-loaded compliance.
- **Few clusters problem:** 7 BAT sectors means cluster-robust SEs are unreliable. RI provides non-parametric alternative.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT R1, GPT R2, Codex; Gemini FAIL on minor N discrepancy)
- **Top criticism:** Internal consistency — post-treatment year counts, country counts, treatment timing vs. data scope needed harmonization across 7+ locations
- **Surprise feedback:** Advisors flagged sample size bridging (Table 1 N=3,994 vs regression N=3,843) repeatedly; adding explicit notes helped but the N discrepancy concern persisted across rounds
- **What changed:** Fixed 2012-2019→2012-2018 for estimation sample, harmonized all post-treatment year counts (9 for 2016 cohort, 3 for 2022 cohort), clarified country count (30 = EU-27 + NO + UK + CH), fixed "exclude pre-2016 cohorts" to "exclude 2016 cohort" with real estimate, added R², cluster count, and Jensen's inequality note. Took 7 advisor rounds due to compounding consistency issues.

## External Review & Stage C Revision
- **Referee decisions:** R&R (GPT R1), Major Revision (GPT R2), Minor Revision (Gemini)
- **Consensus criticism:** (1) Coarse NACE-to-BAT mapping, especially C20/D/E; (2) 7-cluster inference unreliable; (3) treatment timing at compliance deadline may miss anticipatory effects; (4) non-EU countries in sample
- **Stage C additions:** Three new robustness checks — sector-specific linear trends (coef=0.043, p=0.30), EU-only sample (0.072, p=0.57), narrow NACE mapping excluding C20/D/E (-0.008, p=0.79). Elevated RI as primary inference. Tempered language throughout.
- **Prose review:** Rated "top-journal ready." Applied targeted improvements: varied rhythm in intro sector list, punchier results language, removed "two features are apparent" throat-clearing.

## Summary
- **Key lesson:** Internal consistency across a 35-page paper with many cross-referenced numbers (N, post-treatment years, country counts, cohort descriptions) is the main bottleneck for advisor review. Fix all instances simultaneously rather than iteratively.
- **Null result papers:** Can pass review if the null is well-identified, clearly explained with candidate mechanisms, and accompanied by strong validation (CO2 placebo, RI, leave-one-out). Reviewers respect honest nulls but demand robust inference.
- **Few-cluster inference:** With 7 treatment clusters, RI must be the primary tool. Don't lean on sector-country or country clustering as reassurance — reviewers correctly note these cluster below the treatment-assignment level.
