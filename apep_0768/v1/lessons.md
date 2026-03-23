## Discovery
- **Idea selected:** idea_1696 — Film tax credits with QWI demographic data, overturning Button (2019)'s TWFE null
- **Data source:** QWI Parquet on Azure — fast access, 4.4M rows for race data, all states 2001-2024
- **Key risk:** TWFE bias story depends on never-treated states being valid controls

## Execution
- **What worked:** Azure QWI data access was seamless; CS-DiD produced clear results with clean pre-trends; the TWFE sign-flip story is compelling (−0.038 vs +0.220)
- **What didn't:** Racial decomposition via CS-DiD failed due to sparse Black/Hispanic panels in small states' NAICS 512; had to fall back to TWFE for race columns, undermining the equity angle
- **Review feedback adopted:** Fixed abstract/table ATT mismatch (0.397→0.220); retitled to drop "Equity?" claim; clarified table estimator labels; added cost-per-job back-of-envelope ($115-140K); softened TWFE "bias" rhetoric per Qwen reviewer
