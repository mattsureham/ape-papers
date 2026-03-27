## Discovery
- **Idea selected:** idea_0969 — Switzerland Second Home Initiative sectoral reallocation test. Selected from 10 random candidates based on high treated unit count (337), long pre-period (18 years), surprise referendum, and vivid "reallocation mirage" framing.
- **Data source:** BFS PxWeb API (construction investment) + ARE Wohnungsinventar (STAC API). BFS PxWeb required understanding the table nesting (listing vs. endpoint) and year-by-year fetching to stay within limits. ARE data required discovering the STAC endpoint on data.geo.admin.ch — the geo.admin.ch identify API only returned a subset.
- **Key risk:** Pre-trends in alpine vs. non-alpine municipalities. Resolved with canton×year FE.

## Execution
- **What worked:** Canton×year FE dramatically improved identification — roads placebo went from significant to insignificant. The continuous intensity specification provided independent confirmation. The sectoral decomposition (BFS Table 203 with 12 categories) gave rich mechanism evidence.
- **What didn't:** The naive DiD without canton FE was misleading — showed huge effects everywhere including the placebo. The RDD at 20% was underpowered and showed opposite-sign estimates, possibly due to loophole reclassification.
- **Review feedback adopted:** Fixed heterogeneity table to use canton×year FE (Grok caught inconsistency). Strengthened pre-trends discussion with magnitude comparison. Qualified claims as "suggestive" rather than definitive.
