## Discovery
- **Idea selected:** idea_0324 — EU bank branch closures post-CRD IV, linking financial regulation to regional economic outcomes via Bartik design
- **Data source:** Eurostat (employment, GDP, unemployment, population, business demography) — all open API, no keys needed. ECB SSI was planned but API blocked; EU-NED election data also inaccessible.
- **Key risk:** NACE K financial employment conflates retail banking with insurance/asset management/fintech

## Execution
- **What worked:** The composition illusion diagnosis is clean and convincing. Three diagnostic tests (pre-trends, non-financial employment decomposition, Eurozone heterogeneity) all converge on the same conclusion. 219 NUTS2 regions across 27 countries give ample variation.
- **What didn't:** Original idea was populist voting, but EU-NED data was inaccessible (Harvard Dataverse returning wrong files). ECB bank office data also blocked. Two data pivots required within the first hour.
- **Review feedback adopted:** Softened title and claims from "did not create deserts" to "cautionary evidence on Bartik identification." Added magnitude interpretation. Added explicit limitations paragraph about granularity of treatment variable and NUTS2 scale.
- **Lesson for future:** NACE K at NUTS2 is NOT a good proxy for retail branch banking exposure. Any future paper on bank branch closures needs institution-level or branch-level data, not sector aggregates. The shift-share literature's "shares must be exogenous" condition is easily violated when the shares proxy for urbanization or economic dynamism.
