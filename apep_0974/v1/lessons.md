## Discovery
- **Idea selected:** idea_1769 — SNAP EA → ED acuity shift (novel Medicaid utilization angle on well-studied treatment)
- **Data source:** T-MSIS (local Parquet, 37M claims) + NPPES extract — no API calls needed, data was on hand
- **Key risk:** Only 18 early-terminating states (close to the 20-unit threshold)

## Execution
- **What worked:** Data pipeline was fast — T-MSIS and NPPES both available locally, 98.5% NPI match rate. Panel construction straightforward. CS-DiD ran cleanly with good pre-trends (2/24 significant).
- **What didn't:** NPI type mismatch (integer vs character) caused two join failures — caught and fixed quickly. Wild cluster bootstrap unavailable (fwildclusterboot not available for R version) — substituted randomization inference.
- **Surprise:** Results completely flipped the hypothesis. Expected ED share increase; got null (RI p=0.842). The log ED result that looked significant under CS-DiD (p<0.05) collapsed under RI (p=0.554). This is an honest, well-powered null.
- **Review feedback adopted:** Added missing-patient mechanism discussion, fiscal back-of-envelope ($900K max per state-month), clarified both ED and PC declining (coverage erosion framing), fixed state count inconsistency. Deferred provider dynamics and dosage analysis to potential V2.
