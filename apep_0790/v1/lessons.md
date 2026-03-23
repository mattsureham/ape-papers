## Discovery
- **Idea selected:** idea_1689 — Fireworks deregulation and air quality. Zero economics papers on US fireworks legalization; clean staggered design with 13 treated states.
- **Data source:** EPA AQS daily PM2.5 (parameter 88101) — pre-generated annual CSV files downloadable from aqs.epa.gov/aqsweb/airdata/
- **Key risk:** Statistical power at state-level with only 9-13 treated states; within-year differencing helps but July 4th weather is noisy.

## Execution
- **What worked:** Within-year differencing is elegant — comparing July 4-5 to adjacent baseline days within same monitor-year eliminates most confounders. Placebo holiday tests (NYE, Memorial Day, random July) all precisely null, providing strong identification support.
- **What didn't:** CS estimator drops states without balanced panels, reducing treated states from 13 to 9. Main effect positive (1.88 µg/m³) but imprecise (p=0.22). EPA CSV format changed in 2020 (date format and quoting), requiring format detection in R.
- **Review feedback adopted:** Fixed incorrect "statistically significant" language (p=0.22 is NOT significant); added magnitude context (0.33 SD); noted imprecision as genuine limitation of 13 treated states.

## Data Notes
- EPA AQS download URL: `https://aqs.epa.gov/aqsweb/airdata/daily_88101_YYYY.zip`
- Date format changed from `YYYY-MM-DD` (≤2019) to `M/D/YYYY` (≥2020) — need `fifelse(grepl("^\\d{4}-", date), ...)` to handle both
- Some zip files extract to subdirectory rather than flat — need recursive file search after unzip
- National July 4 PM2.5 spike: +51% over adjacent days (confirmed, consistent with smoke test)
