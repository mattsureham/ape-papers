## Discovery
- **Idea selected:** idea_0939 — Swiss franc floor removal as an overnight exogenous shock to cross-border shopping incentives. Chose for identification quality (instantaneous, unexpected, large magnitude) and data accessibility (BFS PXWeb, no API keys).
- **Data source:** BFS STATENT via PXWeb API — worked smoothly, zero data access issues. Canton×sector (NOGA 2-digit) panel is the workhorse; municipal panel exists but only has broad sector breakdown (primary/secondary/tertiary), preventing municipal-level retail isolation.
- **Key risk:** Few-cluster inference with 26 cantons. Mitigated by randomization inference and triple-difference with within-canton sector variation.

## Execution
- **What worked:** The event study is textbook — flat pre-trends across all 4 available years, immediate employment effects growing to -9.5% by 2022. The DDD (retail vs non-tradable × border × post) cleanly isolates the retail-specific channel. Non-tradable placebo shows perfect zero (0.007, p=0.86).
- **What didn't:** Municipal-level analysis was diluted because tertiary sector includes too many non-retail services. The establishment count effect is weaker than employment (firms cut workers before closing), which reviewers correctly noted creates a tension with the "desertification" framing. Addressed by discussing the economic logic of the sequencing.
- **Review feedback adopted:** Fixed duplicated table (etable generated the table twice). Added VAT refund institutional detail (effective 30% discount, not just 15%). Clarified why canton-level analysis (data limitation, not preference). Improved border exposure index description. Added discussion of employment/establishment divergence with citations to firm dynamics literature.
