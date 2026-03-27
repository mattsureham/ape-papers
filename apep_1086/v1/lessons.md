## Discovery
- **Idea selected:** idea_0774 — CAA attainment redesignation and manufacturing/pollution rebound. Picked for sharp staggered design (1,561 events), novel question (mirror image of Greenstone 2002), and accessible public data.
- **Data source:** EPA Green Book (PHISTORY XLS), EPA AQS annual concentration files, Census QWI — all public, no credentials needed. Green Book status codes (P/W) weren't documented; had to inspect data.
- **Key risk:** Endogeneity of redesignation timing to manufacturing decline. Addressed with CS estimator, clean pre-trends, and placebo tests but remains the main identification concern.

## Execution
- **What worked:** The question completely flipped — started as "deregulation rebound" and became "environmental ratchet." The data clearly showed no rebound and continued pollution improvement. CS estimator with 362 treated and 2,433 control counties gave a well-powered design.
- **What didn't:** The idea manifest promised TRI facility-level analysis and environmental justice breakdown (employment by race, within-county pollution distribution). Had to drop this for V1 due to data complexity and 8GB RAM constraint. All three reviewers flagged this as the main idea fidelity gap.
- **Review feedback adopted:** Added discussion paragraph distinguishing redesignation from full deregulation (maintenance plan obligations). Pollutant heterogeneity already in robustness table. Equity analysis deferred to V2.
