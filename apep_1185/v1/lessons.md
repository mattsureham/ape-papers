## Discovery
- **Idea selected:** idea_1710 — Kratom bans and opioid mortality; zero prior causal literature, first-order stakes (mortality), drug-type decomposition as structural mechanism test
- **Data source:** CDC VSRR (data.cdc.gov/xkb8-kh2a) — public API, no auth needed, 67K rows. Data are 12-month rolling counts, not monthly flows.
- **Key risk:** Only 5 treated states (3 with clean pre-periods for C-S). Low power for detecting small substitution effects.

## Execution
- **What worked:** Drug-type decomposition as negative control was the paper's strongest design feature. Showing that psychostimulants and cocaine (mechanistically irrelevant to kratom) had the same TWFE pattern as opioids conclusively identified the differential trend confound.
- **What didn't:** The CDC suppresses small-state drug-specific counts, leaving Alabama and Arkansas with 33-38% opioid coverage. This prevented C-S estimation on the opioid-specific outcome. The NCHS data merge proposed in the idea manifest was not attempted due to data structure incompatibility.
- **Review feedback adopted:** Tempered "precise null" to "informative null"; added explicit MDE calculation (~15-20% detectable); added back-of-envelope ecological fallacy calculation. Reviewers unanimously wanted event-study figures — valid but prohibited in V1 format (zero figures).
