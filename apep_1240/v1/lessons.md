## Discovery
- **Idea selected:** idea_0988 — India CGWB groundwater regulation as a "paper tiger" test, exploiting the CAG audit finding of 77% non-compliance
- **Data source:** CGWB monitoring wells from GitHub (craigdsouza/cgwb) — 28K wells, 1996-2017. Clean, easy download. Assessment round data manually compiled from CGWB reports.
- **Key risk:** Block-level identifiers absent from well data, forcing state-level aggregation that dilutes the treatment effect. All three reviewers flagged this.

## Execution
- **What worked:** The depletion RATE specification (first differences) cleanly sidesteps the endogeneity of level-based classification. Pre-trend test on rates is firmly null (p=0.54), while levels show the expected mechanical correlation.
- **What didn't:** Callaway-Sant'Anna estimator failed due to unbalanced panel. The GitHub CSV data lacks block/tehsil identifiers, preventing the sharper Design B (notified vs non-notified blocks) proposed in the idea manifest. The Figshare quality-controlled dataset has block IDs but only 2,759 wells — too few for block-level DiD.
- **Review feedback adopted:** (1) Softened mechanism claims from "three mechanisms explain" to "three mechanisms are consistent with the evidence." (2) Expanded discussion of state-level treatment limitation with clearer acknowledgment that block-level effects could exist. (3) Added paragraph on measurement error and MDE interpretation. (4) Clarified classification vs notification terminology.
