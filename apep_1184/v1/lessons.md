## Discovery
- **Idea selected:** idea_0916 — EU airport slot waiver provides first exogenous variation in 30 years of slot regulation, with dose-response staircase (0→50→64→80%) and built-in placebo (charter flights)
- **Data source:** Eurostat avia_paoa — JSON-stat API with server-side filters essential for this large table (50MB compressed). No API key needed.
- **Key risk:** Differential COVID recovery at hub vs regional airports confounding the slot mechanism

## Execution
- **What worked:** Country×year fixed effects were the decisive specification. Within-country comparisons (Frankfurt vs Dortmund, CDG vs Lyon) cleanly isolate the slot mechanism from differential COVID recovery. The charter placebo and size-matching both confirm the null.
- **What didn't:** The naive DiD (airport + year FE) produces a highly significant but misleading result (-16.7%, p<0.001). This would have been published as evidence that slot waivers harm competition — a cautionary tale about absorbing group-specific trends.
- **Review feedback adopted:** Added pre-trend acknowledgment, MDE/power discussion, route-level caveat, quarterly results mention. All text edits, no re-analysis needed.
