## Discovery
- **Idea selected:** idea_2441 — Denmark's 2020 Blackstone-Indgreb closing §5 stk. 2 renovation arbitrage, exploiting opt-out municipality design
- **Data source:** Statistics Denmark StatBank API (BYGV11 building permits, BOL101 dwelling stock) — no authentication needed, BULK format required for large queries
- **Key risk:** Control group (18 rural/island opt-out municipalities) structurally different from treated urban municipalities

## Execution
- **What worked:** The renovation trap framing; the pipeline-clearing interpretation of the delayed effect; multifamily permits as a closer proxy for the targeted channel
- **What didn't:** Property sale data (EJ131) only at region level, not municipality — had to pivot to building permits. §5 stk. 2 application data not available via API. Full-panel TWFE muddied by pre-2015 urban-rural divergence.
- **Review feedback adopted:** Added extensive discussion of COVID/macro confounders; acknowledged outcome-mechanism gap (permits vs. renovations); expanded heterogeneity analysis (large cities vs. other treated)
