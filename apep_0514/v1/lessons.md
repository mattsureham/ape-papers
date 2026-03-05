## Discovery
- **Policy chosen:** France's 2017 cumul des mandats ban — clean pre/post shock affecting ~45% of constituencies, rich fiscal data from DGFiP/OFGL
- **Ideas rejected:** French housing (DVF) — too well-studied; Energy (eCO2mix) — no clear policy shock; Labor (France Travail) — API access issues
- **Data source:** DGFiP commune budgets (2008-2017) + OFGL (2020, 2023). OFGL years 2018-2019, 2021-2022 unusable due to missing agrégat coverage. Critical unit mismatch: DGFiP in thousands, OFGL in actual euros.
- **Key risk:** Post-treatment data limited to 2 observations (2020, 2023), one during COVID

## Review
- **Advisor verdict:** 4 of 4 PASS (after fixing Table 1 constituency count reversal, adding triple-diff/HonestDiD appendix tables, fixing timing language)
- **Top criticism:** All 3 referees flagged constituency-level aggregation as diluting potential "home commune" pork effects — the most important limitation
- **Surprise feedback:** GPT-5.2 gave Major Revision while Grok and Gemini gave Minor — GPT focused heavily on the estimand/exposure mismatch
- **What changed:** Added joint F-tests, COVID-exclusion robustness, recalibrated claims from "no pork-barrel" to "no detectable constituency-level effects", explicitly acknowledged home-commune limitation as top priority for future work

## Summary
- **Main finding:** Comprehensive null across all fiscal outcomes (investment, equipment, grants, opex, revenue, debt) — the cumul ban had no detectable constituency-level fiscal cost
- **Time to produce:** ~2 hours from discovery to publication
- **Biggest challenge:** OFGL data quality — only 2020 and 2023 had complete agrégat coverage, unit mismatch nearly introduced a factor-of-1000 error
- **Lesson for future:** Always verify units when combining administrative data sources; constituency-level aggregation is appropriate for constituency-level treatment but may miss commune-specific effects
