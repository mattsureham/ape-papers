## Discovery
- **Idea selected:** idea_0052 — Marijuana tax earmarking and education spending fungibility. Novel causal test of fiscal fungibility using staggered state legalization.
- **Data source:** Census Annual Survey of School System Finances (XLS files 2008-2022). Downloaded successfully for all 15 years. Complex multi-sheet Excel format required custom parsing.
- **Key risk:** Small number of treated units (20 states) limits power; Alaska outlier dominates aggregate estimate.

## Execution
- **What worked:** Clean data pipeline from raw Census XLS to balanced panel. CS-DiD with `did` package ran smoothly. Revenue decomposition and federal placebo provided clean falsification. Earmark heterogeneity analysis yielded the paper's main contribution.
- **What didn't:** Aggregate ATT insignificant due to Alaska (singleton 2016 cohort with $23K+ per-pupil spending during oil crisis). Passthrough ratio > 1 complicates interpretation — spending increase 5x marijuana revenue makes pure fiscal channel implausible.
- **Review feedback adopted:** Qualified abstract to acknowledge Alaska sensitivity; expanded discussion of why marijuana earmarks may differ from lottery earmarks (salience, magnitude, institutional design); added Conley-Taber and Goodman-Bacon citations; acknowledged heterogeneity analysis as exploratory; noted missing manifest placebos (non-education spending, property tax).
- **Lesson for future:** With ≤20 treated units, singleton cohort outliers can dominate. Consider leave-one-out diagnostics early. Passthrough ratios > 1 signal the treatment captures more than the direct mechanism — reframe the estimand.
