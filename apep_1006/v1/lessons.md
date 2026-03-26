## Discovery
- **Idea selected:** idea_1795 — FATF grey-listing and remittance costs. Chosen for sharp institutional lever (FATF plenary decisions at known dates), massive treatment variation (70+ cohorts, 114 countries), first-order welfare question, and corridor-level data
- **Data source:** World Bank RPW (247K firm-level obs, 378 corridors) + FATF plenary records (74 episodes, 63 countries) + WDI remittance volumes
- **Key risk:** RPW download URL had changed (now date-stamped); data split across two Excel sheets requiring merge

## Execution
- **What worked:** CS-DiD with 24 treatment cohorts, clean pre-trends across 8 pre-treatment quarters, comprehensive robustness (sending-country placebo, channel heterogeneity, extensive margin, entry-exit asymmetry)
- **What didn't:** Expected a positive effect (higher costs from de-risking); found a credible null instead. Had to pivot the framing from "grey-listing raises costs" to "grey-listing does NOT raise costs — why?"
- **Review feedback adopted:** All three reviewers flagged the missing BIS analysis and the 24 vs 70+ cohort discrepancy. Added explicit justification for cohort construction, acknowledged BIS scope limitation, and nuanced the policy implications to distinguish retail price effects from wholesale financial intermediation effects. Also added caveat about informal channel substitution.

## Key Insight
The widely cited claim that FATF grey-listing raises remittance costs does not hold in corridor-level pricing data. The mechanism may work through volumes (formal flows shift to informal channels) rather than prices, or MTOs' proprietary networks insulate them from correspondent banking de-risking.
