## Discovery
- **Idea selected:** idea_2036 — Section 301 tariffs racial decomposition. Third choice after UPHPA (idea_1693, already published as apep_0846) and Florida lottery licenses (idea_1804, already published as apep_0865).
- **Data source:** QWI race × 3-digit NAICS from Azure (2.87M rows manufacturing), Census International Trade API (import penetration by NAICS). Both worked on first attempt.
- **Key risk:** Shift-share identification in the presence of pre-existing racial composition trends across industries.

## Execution
- **What worked:** Azure DuckDB connection (after fixing shell escaping and integer column types). QWI data quality is excellent — 850K analysis cells across 2,713 counties. Census trade API returned clean NAICS-level Chinese import penetration.
- **What didn't:** Initial Azure connection via `apep_azure_connect()` failed due to connection string parsing. Fixed by using direct DuckDB `CREATE SECRET` with explicit connection string. Also, industry column stored as BIGINT required integer range filter instead of LIKE pattern.
- **Key design insight:** Industry × quarter FE absorbs the industry-level tariff rate × post interaction. Bartik county-level exposure is necessary for the preferred specification. The industry-level spec reveals pre-existing racial composition trends (placebo test fails), validating the Bartik approach.
- **Review feedback adopted:** Toned down causal claims (shift-share for broad policy shock), acknowledged GDELT omission as limitation, reframed conclusion from "definitive null" to "no detectable large-scale effect." Both reviewers flagged the positive Bartik coefficient as suspicious — kept but discussed as potential import substitution.
