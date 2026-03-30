## Discovery
- **Idea selected:** idea_2056 — OxyContin reformulation brand share as IV for labor market scarring. Chosen for first-order stakes (opioid crisis), universe administrative data (ARCOS 178M transactions + QWI), and novel angle (no prior paper applies this instrument to labor outcomes).
- **Data source:** DEA ARCOS (Azure, 178.6M rows) + Census QWI (Azure, 51 state files). Both streamed via DuckDB without local download.
- **Key risk:** Exclusion restriction for labor outcomes — OxyContin brand share driven by marketing territories may correlate with economic trends.

## Execution
- **What worked:** Azure data pipeline delivered both ARCOS and QWI cleanly. ARCOS date format (MMDDYYYY as numeric) required year extraction via modulo. QWI files use lowercase state abbreviations. FIPS matching via tigris achieved 94.9%.
- **What didn't:** Census Population Estimates API endpoints for 2005-2014 were down; fell back to ACS 2010 5-year. The modelsummary package changed its output format (now uses tinytable), requiring manual LaTeX table generation instead.
- **Surprise finding:** The reduced-form relationship is null/slightly positive — completely contrary to the hypothesis. Elderly workers show the same pattern as prime-age, strongly suggesting the instrument captures economic trends, not opioid-specific variation.
- **Review feedback adopted:** Added event study coefficient table, moderated exclusion restriction language, added power/MDE discussion, reframed as reduced-form paper (not IV). All three reviewers converged on these points.
- **Lesson for future work:** Instruments validated in one domain (pharmacological substitution → mortality) should not be assumed valid for other domains (labor markets) without testing. The "instrument boundary" concept is real and important.
