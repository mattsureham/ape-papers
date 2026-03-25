## Discovery
- **Idea selected:** idea_1668 — Alkaline hydrolysis legalization, chosen for zero prior economics literature, niche setting with portable mechanism (tech vs behavioral barriers to competition), and 22+ treated states
- **Data source:** BLS QCEW API — county-level data 76% suppressed for employment (small establishments), but establishment counts available everywhere; state-level has no suppression
- **Key risk:** Small effect size in a low-frequency industry; NAICS classification doesn't distinguish AH providers from traditional funeral homes

## Execution
- **What worked:** Two-panel approach (county establishments + state employment/wages) was effective for handling QCEW disclosure. CS-DiD with staggered adoption worked cleanly for establishments and employment. The "grief premium" framing resonated with all three reviewers.
- **What didn't:** Wage pre-trends failed — significant negative coefficients at t-5 and t-4. Had to de-emphasize wage results as suggestive only. County-level establishment effect is positive but imprecise (mean of 5.0 establishments per county makes 0.19 hard to detect).
- **Review feedback adopted:** Strengthened mechanism discussion (entry vs adaptation), added welfare calculation, acknowledged cluster count limitations, improved honest treatment of wage pre-trends
