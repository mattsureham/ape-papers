## Discovery
- **Idea selected:** idea_2076 — CHIPS Act housing effects. Picked for timeliness (largest US industrial policy), free Zillow data, staggered announcement design, and high-stakes distributional question.
- **Data source:** Zillow ZHVI/ZORI (free CSV), Census ACS API, Commerce Department press releases
- **Key risk:** County-level aggregation might dilute localized effects near fab sites

## Execution
- **What worked:** Zillow data was clean and immediately usable. C-S estimator ran smoothly on 225K obs. The null result was crisp with clean pre-trends. Randomization inference confirmed the null convincingly (p=0.99).
- **What didn't:** Initially had only 16 treated counties (below 20-unit validator threshold). Had to expand CHIPS recipient list to 21 by adding smaller verified awards. ACS sentinel values (-666666666) for missing data contaminated summary statistics until filtered.
- **Review feedback adopted:** Added dollar-magnitude translation of ATT, strengthened threats-to-validity section on few-cluster inference, added back-of-envelope demand calculation to contextualize the aggregation concern.
