## Discovery
- **Idea selected:** idea_1028 — UK PCC electoral cycles in investigation quality; strong institutional variation with built-in placebos
- **Data source:** Home Office Crime Outcomes Open Data Tables (XLSX from gov.uk) — 10 years of quarterly data, 5M+ records
- **Key risk:** Only 2 non-PCC control forces (Met + City of London); collinearity prevents within-PCC event study

## Execution
- **What worked:** Data acquisition from gov.uk was comprehensive once the right URLs were found; the stacked DiD framework cleanly separated election cohorts
- **What didn't:** Police UK API only covers 2023+, wasting initial data fetch time; pre-2014 annual data uses incompatible outcome coding; all PCC elections are simultaneous, forcing reliance on non-PCC controls
- **Review feedback adopted:** Strengthened limitations section with MDE discussion, pre-reform data gap acknowledgment, and explicit control-group fragility framing
