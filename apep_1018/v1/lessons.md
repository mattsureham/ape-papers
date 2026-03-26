## Discovery
- **Idea selected:** idea_1802 — OSHA SIR peer reporting and media salience. Picked after idea_1621 (Armenia/NK) failed due to ARMSTAT API inaccessibility.
- **Data source:** OSHA SIR (97K records, direct download), BLS QCEW (API), FEMA disasters (API). GDELT BigQuery inaccessible (no ADC).
- **Key risk:** No credible IV for causal identification. Pivoted from IV paper to honest descriptive piece.

## Execution
- **What worked:** OSHA SIR data is excellent — 103K establishment-level records with NAICS, geocodes, injury narratives. Panel construction (sector × state × quarter) is clean. The "compliance shadow" framing emerged organically from the data.
- **What didn't:** BigQuery/GDELT inaccessible (no ADC credentials). FEMA disasters collinear with quarter FE. IV approach abandoned entirely.
- **Review feedback adopted:** Added back-of-envelope effect-size translation (0.78 reports per 1-SD shock = 11% of unreported inventory). Explicitly noted media-salience null as a finding. Softened one causal claim in conclusion.
