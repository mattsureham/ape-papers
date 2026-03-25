## Discovery
- **Idea selected:** idea_0473 — EO 13771 regulatory budget with continuous DiD, chosen for massive sample (38K NPRMs), sharp on/off dates, and built-in reversal test
- **Data source:** Federal Register API (no key required) — pivoted from Regulations.gov API (requires key we don't have)
- **Key risk:** Only 40 agencies = few clusters for inference; WCB confirmed this is binding

## Execution
- **What worked:** Year-by-year API fetching to avoid 10K cap; RIN-matching for NPRM-to-final-rule durations; continuous treatment design with significance share
- **What didn't:** WCB p-value (0.52) showed the 18pp composition result doesn't survive small-sample corrections. With 40 clusters, cluster-robust SEs overstate precision.
- **Key pivot:** Rewrote the paper from "compositional effect is the main finding" to "suggestive evidence of compositional channel that needs confirmation" — honest reporting of imprecise results
- **Review feedback adopted:** Added identification threat discussion (Trump deregulation confound); added WCB reporting; softened all claims; noted treatment-outcome circularity concern; flagged missing eo13771Designation field as future work
- **Lesson for future papers:** 40 clusters is marginal — tournament judges punish imprecise designs. Consider disaggregating to sub-agency or rule-level to get more power. Also: always check WCB before claiming significance with few clusters.
