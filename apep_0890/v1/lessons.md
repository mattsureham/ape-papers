## Discovery
- **Idea selected:** idea_0464 — Craigslist's staggered metro entry as treatment for county-level publishing employment
- **Data source:** QWI NAICS 513 from Azure (326K rows, 3,125 counties); Craigslist entry dates from published literature (133 CBSAs)
- **Key risk:** Imprecise estimates due to NAICS 513 including non-newspaper publishing; control group sensitivity

## Execution
- **What worked:** Azure data extraction via Python DuckDB bridged to R analysis; Callaway-Sant'Anna implementation ran cleanly; leave-one-cohort-out stability was reassuring
- **What didn't:** R's DuckDB Azure extension had URL parsing bug (v1.4.4) — required Python extraction bridge; HonestDiD failed on the event-study coefficients (NA values from reference periods); pre-trend at e=-2 is noisy
- **Review feedback adopted:** Fixed spurious significance stars (p-value pipe bug); converted thebibliography to proper .bib
- **Key finding:** TWFE-to-CS-DiD sign reversal (positive → negative) demonstrates forbidden comparison bias in canonical staggered setting; point estimate is imprecise but leave-one-out confirms negative direction
