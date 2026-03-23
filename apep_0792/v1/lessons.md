## Discovery
- **Idea selected:** idea_1068 — Colombia-Venezuela trade collapse as natural experiment for export diversification
- **Data source:** WITS/Comtrade (sector-level bilateral trade) + World Bank WDI
- **Key risk:** 16 sectors = few clusters for inference; Comtrade v1 API deprecated, used WITS SDMX instead

## Execution
- **What worked:** WITS API provided clean sector-group data. Pre-crisis Venezuela shares range from 0.3% (fuels) to 73% (animals) — excellent variation. Strong main result (β=-1.22, p=0.025) with clean diversification null.
- **What didn't:** Comtrade v1 API returned HTML (deprecated). Had to switch to WITS SDMX API with XML parsing. Only 16 broad sector groups available (not individual HS2 codes via WITS API).
- **Review feedback adopted:** Reviewers flagged few-cluster inference and missing event-study figures. Both are V1 format limitations — noted for revision. Paper text acknowledges cluster count concern.
