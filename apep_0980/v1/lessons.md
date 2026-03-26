## Discovery
- **Idea selected:** idea_1885 — IRA energy community bonus credit. First quasi-experimental estimate of this major place-based clean energy incentive. QWI data already on Azure eliminated acquisition risk.
- **Data source:** QWI (33GB on Azure Blob) + FRED API for county unemployment. BLS LAUS flat files returned 403 across all years — needed FRED fallback with corrected "A" suffix series format.
- **Key risk:** Endogeneity of unemployment criterion — counties that qualify have high unemployment because their economies are declining, which also depresses construction employment.

## Execution
- **What worked:** Azure DuckDB query returned 525K rows in seconds. Treatment construction from QWI mining shares + FRED unemployment was clean. 271 treated, 303 FF-eligible controls.
- **What didn't:** Pre-trends at e=-3 and e=-2 in CS dynamic effects confirm the selection concern. Full-sample TWFE picks up secular decline in fossil fuel counties.
- **Review feedback adopted:** Added treatment measurement subsection, power analysis, and MSA-to-county mapping clarification per code advisor and Qwen empirics reviews. Both reviews flagged pre-trend selection via unemployment criterion — already acknowledged in paper.
