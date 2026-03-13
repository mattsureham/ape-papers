## Discovery
- **Idea selected:** idea_0442 — Eisensee-Strömberg competing-news IV applied to MSHA mine safety enforcement
- **Data source:** MSHA Open Government Data (accidents, inspections, violations), FEMA OpenFEMA API (disaster declarations), FRED (VIX)
- **Key risk:** BigQuery unavailable (403) for GDELT data; pivoted to FEMA disasters as competing-news instrument

## Execution
- **What worked:** MSHA data is comprehensive and clean (3M+ violations, 271K accidents). FEMA API paginated well. Reduced-form design is clean and transparent. Null result is well-powered and robust across many specifications.
- **What didn't:** BigQuery ADC credentials had wrong project, blocking GDELT access. Had to pivot instrument from GDELT events to FEMA disasters, which reviewers flagged as a weaker exclusion restriction. modelsummary LaTeX output required manual table construction.
- **Review feedback adopted:** Fixed all GDELT→FEMA references in SDE table and balance test notes. Paper already had limitations discussion acknowledging missing first-stage and peer-mine analysis.
