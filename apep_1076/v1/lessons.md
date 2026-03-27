## Discovery
- **Idea selected:** idea_1701 — Conversion therapy bans with YRBSS data. High stakes (youth suicide), 24 treated states, free public data.
- **Data source:** CDC YRBSS SADC — URLs had changed from prior documentation; had to discover new file structure. Fixed-width ASCII parsing required downloading the SPSS syntax file for exact column positions.
- **Key risk:** Sexual identity question only available in 2021-2023 waves, limiting the planned DDD to a cross-sectional comparison.

## Execution
- **What worked:** Population-level DiD is clean and compelling. The "destigmatization dividend" framing — naming the mechanism — makes the paper more than just a policy evaluation. The LGB heterogeneity result (-4.5pp suicide attempts) is the paper's strongest finding.
- **What didn't:** WebFetch gave incorrect SPSS column positions; always verify fixed-width format specs against the actual syntax file. The Callaway-Sant'Anna estimator produces much smaller estimates when run on 39 state-year means vs. 743K individual observations — aggregation kills power.
- **Review feedback adopted:** Added event study discussion, expanded CS vs TWFE interpretation, strengthened limitations section on policy bundling confound.
