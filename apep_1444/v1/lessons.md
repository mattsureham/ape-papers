## Discovery
- **Idea selected:** idea_2496 — Ecuador non-contributory pension RDD at age 65. CONFIRMED feasibility, multi-threshold design, unexploited gap (no causal estimates on this program for the elderly poor).
- **Data source:** ENEMDU from INEC Ecuador — URL patterns vary by year, only 7 of 20 quarters downloadable via direct links. Future papers: try the INEC open data bank portal.
- **Key risk:** Age is integer-valued → mass points in running variable. Handled by rdrobust's mass-point adjustment.

## Execution
- **What worked:** Clean first stage (6.7pp jump in transfer receipt), valid design (McCrary p=0.20, covariate balance clean), strong heterogeneity finding (urban-rural split).
- **What didn't:** The aggregate LFP effect is borderline (p=0.046). The poor subsample shows a precise null — the manifest predicted effects among the poor, but subsistence constraints dominate. The placebo at age 60 is significant, which weakens the design slightly.
- **Review feedback adopted:** [to be filled after reviews]
