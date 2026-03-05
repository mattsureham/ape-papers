## Discovery
- **Policy chosen:** Section 1115 SUD demonstration waivers — staggered adoption across 37 states (2017-2024), clear treatment dates, novel supply-side angle
- **Ideas rejected:** NP-FPA (studied extensively), cannabis legalization (too many existing papers), opioid settlements (timing too recent for data), MCO mandates (weak variation)
- **Data source:** T-MSIS Provider Spending Parquet (227M rows) + NPPES — Arrow filtered aggregation worked well on 16GB RAM after switching from full-table collect to code-prefix-filtered queries
- **Key risk:** Small cluster count (43 states) and many treatment cohorts (19 unique timing groups) created noisy CS-DiD estimates; results ended up being an important null

## Execution
- **DuckDB vs Arrow:** DuckDB compilation failed on ARM Mac; Arrow with pre-filtered queries (H-codes only, then J-codes, then T-codes separately) was the winning strategy for 16GB RAM
- **Result surprise:** Expected positive supply effects; found mostly null/imprecise results. CS-DiD positive (0.22, p=0.12) but TWFE and stacked DiD near zero. SUD-specific providers showed negative effect. Honestly reported as important null result.
- **Placebo success:** Personal care T-codes correctly null (p=0.58), validating the research design

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT-5.2 failed on internal consistency — kept finding text inconsistencies through 5 rounds)
- **Top criticism:** All 3 referees wanted MCO/managed care heterogeneity analysis and SUD decline decomposition
- **Surprise feedback:** GPT referee deeply skeptical that NPI counts = "capacity" — valid point about billing participation vs actual workforce
- **What changed:** Added sample sizes to all tables, fixed 8+ internal consistency issues (state counts, waiver dates, rounding), added MDE/power discussion, strengthened implementation lag and estimator sensitivity discussion
