## Discovery
- **Idea selected:** idea_2131 — India's 2008 Delimitation and ST reservation rotation on deforestation; nationwide scope improves on single-state studies
- **Data source:** SHRUG DMSP nightlights (district-year) + Hansen Global Forest Change (9 tiles, 30m) + GADM boundaries + Census 2011 PCA
- **Key risk:** Constituency-level data inaccessible (TCPD API down, SHRUG requires web form), forced district-level analysis

## Execution
- **What worked:** Trend-break specification elegantly solved the massive pre-trend problem. The naive DiD (+1.64) was entirely an artifact of pre-existing convergence. The SC placebo (opposite sign) strengthened ST-specificity. Forest loss data from Hansen GFC provided mechanism evidence.
- **What didn't:** GEE authentication unavailable; GFC tile-by-tile extraction hit memory limits on large tiles; had to use partial coverage. State-level ST share matching for forest panel is noisy. District-level analysis sacrifices the sharp constituency-level variation the idea promised.
- **Review feedback adopted:** Added explicit paragraph about district-level limitation; softened "guardian effect" language to "suggestive"; acknowledged natural convergence deceleration as alternative; added note about Red Corridor operations as potential confounder.
- **Key lesson:** Always check for pre-trends BEFORE framing the paper. The event study saved this paper from a false positive. The honest null + trend-break finding is a more interesting and credible contribution than the naive positive would have been.
