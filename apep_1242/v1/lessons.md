## Discovery
- **Idea selected:** idea_2219 — UK PSC register bunching at 25% beneficial ownership threshold; first economics paper applying bunching to BO transparency
- **Data source:** Companies House PSC bulk snapshot (free, no API key) + Basic Company Data CSV
- **Key risk:** Cross-sectional design limits causal claims; polynomial counterfactual sensitivity for skewed discrete distributions

## Execution
- **What worked:** The configuration test (equal-split puzzle at k=4 vs k=3 placebo) was model-free and extremely powerful. Data parsing from bulk JSON-lines snapshots was straightforward once the tempdir bug was fixed.
- **What didn't:** Distributional bunching with polynomial counterfactual was highly sensitive to polynomial order for this extremely skewed distribution (78% at k=1). The temporal difference-in-bunching design from the idea manifest was infeasible because pre-2016 ownership data isn't in the PSC register.
- **Review feedback adopted:** Added explicit acknowledgment that independence benchmark overstates anomaly; clarified coarse bands ≠ exact percentages; added alternative explanations section; reframed identification around k=4 vs k=3 contrast.
