## Discovery
- **Idea selected:** idea_0357 — NIBRS measurement artifact, chosen for sharp identification (murder placebo), massive sample (40 states, 16 cohorts), and portable mechanism (hierarchy rule removal)
- **Data source:** Disaster Center (compiled FBI UCR) — FBI CDE API was down, pivoted to web-scraping compiled HTML tables
- **Key risk:** State-level analysis vs. originally planned agency-level. Coarseness of treatment definition.

## Execution
- **What worked:** Murder placebo is clean and convincing. CS-DiD estimates are robust across specifications. The framing as a "correction factor for the crime literature" gives the paper broad relevance.
- **What didn't:** FBI CDE API completely non-functional (503/404). Disaster Center pages have duplicated tables (counts + rates) requiring deduplication. Heterogeneity analysis failed for population splits (too few never-treated small states).
- **Review feedback adopted:** Expanded limitations section to acknowledge agency-level ideal, wild cluster bootstrap, missing direct mechanism test. Fixed Table 1 observation count confusion. Added nuance to murder placebo discussion (7% point estimate acknowledged). Clarified that event study uses TWFE while main estimates use CS-DiD.
