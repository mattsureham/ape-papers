## Discovery
- **Idea selected:** idea_1904 — Grenfell fire + regulatory cascade → fire safety industry creation
- **Data source:** Companies House Free Company Data Product (bulk CSV, 5.6M companies) + NOMIS Census KS401EW dwelling data
- **Key risk:** Flat share proxy for treatment intensity captures urban dynamism broadly, not just fire safety demand

## Execution
- **What worked:** The regulatory phase decomposition (2.3→3.4→4.5→11.2) is the paper's strongest result — a monotonically escalating pattern across four distinct regulatory milestones. The outward-code geocoding strategy (2,812 outcodes instead of 153K full postcodes) achieved 99.3% match rate in minutes instead of hours.
- **What didn't:** The control construction SIC "placebo" is significant (β=4.98), meaning high-flat LAs saw more of ALL construction firm types post-2017. This forced reframing around the triple-difference as the clean specification.
- **Review feedback adopted:** All three reviewers flagged SIC code noise and the registered-office-vs-activity concern. Expanded limitations section to acknowledge these explicitly. Reviewers also wanted flat share validated against DLUHC remediation data and a DDD event study — left these for V2 revision. The "regulatory genesis" framing received positive feedback from all reviewers.
