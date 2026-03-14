## Discovery
- **Idea selected:** idea_0119 — Performance-based funding for higher education (cream-skimming hypothesis)
- **Original idea (abandoned):** idea_0088 (CON repeals) — released due to insufficient data coverage; most repeals predated available CBP NAICS data
- **Data source:** IPEDS via local DuckDB (1.2GB, 23 tables) — instant access, no API delays
- **Key risk:** Pre-trends in CS-DiD completions model (p=0 for pre-test), though aggregated pre-treatment coefficients are near zero

## Execution
- **What worked:** IPEDS DuckDB made data access trivial; 727 public 4-year institutions with 25 treated states provides excellent power; the private-institution placebo is a convincing falsification test
- **What didn't:** Column names in DuckDB differed from standard IPEDS documentation (e.g., `institution_name` vs `instnm`, `state` vs `stabbr`); GR table structure required using GR200 instead; enrollment filter needed `line=29` not `line=1`
- **Review feedback adopted:** (1) Added levels vs shares distinction for minority enrollment — reviewers correctly identified that share decline doesn't imply displacement; (2) Moderated cream-skimming claims to "suggestive evidence" with "differential recruitment" framing; (3) Attempted Pell share analysis but data too sparse (only 43 institutions with enough obs); (4) Fixed sample size inconsistency in abstract
- **Key finding:** Precise null on completions (CS ATT = -0.020), significant cream-skimming (minority share -1.6pp)
