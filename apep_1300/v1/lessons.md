## Discovery
- **Idea selected:** idea_1523 — Amazon FC staggered entry × QWI race panel. Selected for sharp institutional lever (discrete FC openings), admin microdata (QWI repeatedly praised by tournament judges), and portable mechanism framing ("racial dividend").
- **Data source:** QWI from Azure (3.4M rows, clean), Amazon FC locations from MWPVL gist (93 facilities, 63 counties). MWPVL's main site now uses images — had to use archived CSV compilation.
- **Key risk:** Small treatment sample (63 counties) and potential endogeneity of FC location to county growth.

## Execution
- **What worked:** Callaway-Sant'Anna gave clean pre-trends and large, significant effects. The racial decomposition (Black ATT 0.49 vs White 0.28) tells a compelling story. Azure QWI data is high-quality and easy to work with via Python DuckDB (R DuckDB Azure extension was broken).
- **What didn't:** R DuckDB Azure extension fails with "URL using bad/illegal format" error on v1.4.4 — had to use Python DuckDB to extract data as CSV, then load in R. Year parsing from MWPVL gist required careful regex (dates like "October 142014" matched wrong digits initially).
- **Review feedback adopted:** (1) Acknowledged covariance issue in racial dividend SE calculation. (2) Added magnitude benchmarking comparing ATT to FC employment capacity. (3) Softened welfare/causality language. (4) Noted missing triple-difference as explicit future work. (5) Clarified treatment sample scope (63 counties pre-2017 vs 300+ full network).
