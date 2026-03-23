## Discovery
- **Idea selected:** idea_1170 — Romania micro-enterprise threshold bunching (highest-win-rate method)
- **Data source:** Eurostat SBS — ANAF firm-level data not programmatically accessible (data.gov.ro returns headers only)
- **Key risk:** Design pivot from bunching to cross-country DiD due to data limitations

## Execution
- **What worked:** Eurostat data fetching via `eurostat` R package was reliable; cross-country panel construction was straightforward; null result is cleanly documented with multiple robustness checks
- **What didn't:** ANAF data inaccessible — the idea manifest's bunching design required firm-level turnover data that couldn't be downloaded programmatically. INS TEMPO API also didn't expose turnover-based size classes. Had to pivot to aggregate cross-country DiD, which is fundamentally weaker than the planned bunching design.
- **Review feedback adopted:** Added explicit acknowledgment of ANAF data limitations, event study pre-trend analysis in main text, measurement limitation discussion (employee vs. turnover proxy), Cameron et al. (2008) reference for few-cluster inference
- **Key lesson:** Before claiming an idea that requires specific data (like "ANAF's public firm-level API"), verify actual bulk download access during the data exploration phase. The "smoke test" in the manifest may have confirmed API existence but not bulk data retrieval capability.
