## Discovery
- **Idea selected:** idea_1492 — Section 232 tariffs × QWI race panel, chosen for sharp institutional lever and triple-diff design
- **Data source:** QWI Race-Hispanic panel from Azure (8.67M rows) + Census CBP 2016 via API
- **Key risk:** Pre-trends in early pre-period quarters; only sector-level industry data in QWI race panel

## Execution
- **What worked:** Azure helper library for DuckDB connection; CBP API with state-by-state looping; triple-diff design with county×race and race×quarter FEs
- **What didn't:** Direct Azure connection string via sprintf (shell truncates at semicolons); CBP API uses NAICS2012 not NAICS2017; 4-digit NAICS not available in QWI RH panel
- **Review feedback adopted:** Strengthened event study discussion with formal pre-trend test description; added attenuation bias discussion for pooled upstream/downstream exposure
- **Key finding:** Hiring dividend (0.165, p=0.001) without earnings convergence (-0.028, n.s.) — novel asymmetry that mirrors the China shock literature in reverse
