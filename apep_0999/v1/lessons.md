## Discovery
- **Idea selected:** idea_1839 — UK IR35 off-payroll working rules, bunching at the small company exemption threshold
- **Data source:** NOMIS UK Business Counts (IDBR) via API + Companies House BasicCompanyData bulk download
- **Key risk:** Sizeband-level data (20-49 vs 50-99) limits precision of bunching estimates; can't observe individual firm transitions

## Execution
- **What worked:** The data surprise WAS the paper. The original idea predicted bunching below 50 employees, but the data showed the opposite — a declining ratio. Pivoting to the "compliance trap" narrative (contractor-to-employee conversion pushing firms past the threshold) made for a stronger, more novel contribution than the original bunching prediction.
- **What didn't:** The 20-employee placebo was significant, complicating the attribution to the specific IR35 threshold. Pre-trend marginally significant (p=0.085). Both are honestly reported.
- **Review feedback adopted:** Both reviewers flagged the ecological fallacy of aggregate sizeband data (can't observe individual firm transitions). Also flagged: control group validity (wholesale/retail may differ structurally), significant 20-employee placebo (suggests broader trend beyond IR35 threshold), and need for direct mechanism evidence. Strengthened Discussion section with explicit limitations paragraph addressing aggregation, placebo interpretation, and alternative explanations. The aggregation limitation is fundamental to V1 — a V2 could use Companies House XBRL microdata to track individual firms.
