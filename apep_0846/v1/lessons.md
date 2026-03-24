## Discovery
- **Idea selected:** idea_1693 — UPHPA and Black homeownership. Chose for genuine novelty (zero published evaluations), strong data infrastructure (ACS API confirmed), and clean staggered design (22 states, 30 never-treated).
- **Data source:** ACS 5-year estimates via Census API + tidycensus. Fetched cleanly across all 15 years. No API issues.
- **Key risk:** ACS 5-year smoothing could attenuate short-run effects. Acknowledged as biasing toward null.

## Execution
- **What worked:** Panel construction was smooth (1,606 counties, 24,090 obs). CS estimator and Sun-Abraham both ran without issues. The triple-diff with built-in placebo (white homeownership) provided clean identification support.
- **What didn't:** The overall ATT is a statistical null (0.38pp, SE 1.22). But the event study reveals a compelling dynamic pattern — effects grow to 2.1pp at t+10 (significant). Had to reframe from "UPHPA works" to "UPHPA works slowly."
- **Review feedback adopted:** Added explicit ACS 5-year timing discussion, MDE calculation for the null overall ATT, expanded four-limitation section (including residential homeownership vs. land ownership distinction), better decomposition of cohort composition driving the near-zero average, and clarified triple-diff interpretation.
- **Key lesson:** For slow-acting reforms, the overall ATT can be misleading. Dynamic event studies are essential. Also: naming the mechanism ("the partition trap") made the framing stronger — every reviewer understood the mechanism immediately.
