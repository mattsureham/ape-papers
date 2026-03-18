## Discovery
- **Idea selected:** idea_0079 — Japan's split-rate consumption tax. Chose for clean identification, OECD API access, and built-in 2014 placebo.
- **Data source:** OECD SDMX API (no key required) — monthly CPI by COICOP, 2012-2020. Downloaded 1,404 obs across 13 categories.
- **Key risk:** Short post-treatment window (4 months Oct 2019-Jan 2020 before COVID).

## Execution
- **What worked:** The DiD result is textbook: β=0.018, t=3.50 for restaurant vs food CPI divergence — almost exactly the 0.0185 predicted by full pass-through theory. The 2014 placebo is clean (t=-0.85). Triple-diff is 0.022, t=3.07.
- **What didn't:** The "all treated categories" specification (Model 2) is null because housing, transport, etc. are driven by non-tax factors. The restaurant-specific specification is the right test.
- **Review feedback adopted:** [pending]
