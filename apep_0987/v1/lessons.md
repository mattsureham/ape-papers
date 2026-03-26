## Discovery
- **Idea selected:** idea_0470 — EPA MATS staggered compliance provides rare national-scale natural experiment with three compliance waves
- **Data source:** EIA-860 (plant coordinates/capacity), County Health Rankings (LBW rates), Census SAIPE (economic controls)
- **Key risk:** CDC WONDER requires interactive agreement — pivoted to CHR rolling-window data which dilutes treatment signal

## Execution
- **What worked:** Distance-based county-plant matching (Haversine, 3,221 × 296 matrix). CS-DiD with clean pre-trends (p=0.859). "Compliance paradox" framing for a null result.
- **What didn't:** Compliance wave assignment had to be probabilistic (capacity-based) rather than from actual extension records. CHR 3-year rolling windows attenuate staggered timing. Placebo test on far counties was collinear with year FE.
- **Review feedback adopted:** Added explicit limitations section acknowledging both issues. Added MDE/power analysis to contextualize the null. Strengthened discussion of competing mechanisms.

## Key takeaways for future papers
- CDC WONDER interactive requirement blocks automated access — consider NBER natality files or state-level NVSS instead
- When compliance wave assignment isn't directly observable, the measurement error criticism will dominate reviews
- Null results with clean identification can work, but need explicit power analysis and named mechanisms
