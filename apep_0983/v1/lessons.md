## Discovery
- **Idea selected:** idea_0693 — Swiss Steuerfuss wedge and factor sorting. Chosen for built-in counterfactual (firms vs. residents in same municipality facing different tax rates), which tournament judges reward most highly.
- **Data source:** Canton of Zurich Statistical Office (Steuerfuss, Steuerkraft, population), BFS PXWeb (population cross-validation), ZH OGD datasets 581-596 (STATENT establishment/employment counts). All open access, no API keys needed.
- **Key risk:** Small within-municipality variation in the wedge (range 7-15pp, changes typically 1-2pp). Offset by 38% of muni-years showing changes across 172 municipalities.

## Execution
- **What worked:** The null on physical sorting + significant Steuerkraft effect created a clean, named contribution ("wedge illusion"). BFS PXWeb API works with json-stat2 format (CSV format returns empty). ZH OGD data is reliable and well-structured.
- **What didn't:** BFS STATENT is only available at canton level via PXWeb, not municipality level. Had to use cantonal OGD datasets instead. BL had negligible wedge variation (0.7% vs 38% for ZH), so BL adds little. BFS PXWeb CSV format returned NA for all queries — must use json-stat2.
- **Review feedback adopted:** TBD (reviews in progress)
