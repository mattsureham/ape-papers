## Discovery
- **Idea selected:** idea_0512 — EU Whistleblower Protection Directive + recorded crime (staggered DiD)
- **Original idea (pivoted):** idea_1777 — Patent examiner IV + SCI networks. Failed: BigQuery ADC not configured, PatentsView gated behind auth
- **Data source:** Eurostat (crim_off_cat, sdg_16_50, gov_10a_exp, nama_10_gdp, demo_pjan) + CELLAR SPARQL for transposition dates — all open, no API keys
- **Key risk:** Pre-trends in corruption data; small N (27 countries)

## Execution
- **What worked:** CELLAR SPARQL for transposition dates was excellent — 511 national implementation measures recovered programmatically. Eurostat R package cached data efficiently. The dual-direction prediction (detection vs deterrence) provided a strong framing device.
- **What didn't:** CELLAR returned pre-existing national measures (pre-2019) mixed with actual WPD transpositions — needed manual date filtering. Eurostat column naming inconsistency (`TIME_PERIOD` vs `time`) across datasets caused repeated breakage. CS-DiD parallel trends test rejected (p=0), limiting causal claims.
- **Review feedback adopted:** Fixed Slovakia 2020 singleton (was pre-existing legislation, now coded as 2023). Updated all numbers. Reviewers wanted modern imputation DiD, violent crime placebo, Eurobarometer mechanism validation — good for V2 but beyond V1 scope.
