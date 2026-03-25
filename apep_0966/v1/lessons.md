## Discovery
- **Idea selected:** idea_0878 — EU menthol cigarette ban with cross-country dose-response design. Picked for clean uniform shock, 28-country variation, and first-order welfare question.
- **Data source:** Eurostat HICP (monthly, free API via R `eurostat` package). OxCGRT for COVID controls. Menthol shares from published literature (Laverty 2018, Euromonitor 2019).
- **Key risk:** COVID timing — ban coincided exactly with pandemic. Menthol share correlated with Central/Eastern European geography.

## Execution
- **What worked:** The relative-price design (tobacco/overall HICP) cleanly addressed the inflation confound. Event study pre-trends are clean in the immediate pre-ban window. Triple-difference confirms the null.
- **What didn't:** The naive level specification was confounded by differential post-2020 inflation across CE vs. Southern Europe. Placebo tests on food and alcohol HICP levels failed, forcing a pivot to relative prices. Wild cluster bootstrap failed due to VCOV issues with 28 clusters and 95 time periods.
- **Review feedback adopted:** Strengthened price-vs-quantity limitations, added binary MDE calculation, acknowledged excise tax confound. Did not add EHIS prevalence data (biennial, insufficient for monthly analysis) or excise revenue data (annual, unavailable at needed frequency).
