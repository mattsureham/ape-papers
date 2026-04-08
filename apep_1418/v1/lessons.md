## Discovery
- **Idea selected:** idea_0388 — IPEDS Bartik fiscal shocks to higher education
- **Data source:** IPEDS on Azure DuckDB + FRED state unemployment rates
- **Key risk:** Bartik instrument weakness after year FE absorb national shock

## Execution
- **What worked:** IPEDS data from Azure DuckDB was comprehensive. Research/non-research heterogeneity is a clear, robust finding.
- **What didn't:** Bartik IV is weak (F<4). Bolivia idea (idea_1384) failed due to inaccessible municipal data.
- **Review feedback adopted:** Added caveats about alternative mechanisms for Pell share increase (eligibility expansion, displaced workers, recruitment shifts). Acknowledged OLS-with-trends limitations explicitly.
