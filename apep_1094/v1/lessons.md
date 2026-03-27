## Discovery
- **Idea selected:** idea_1696 — Film tax credits and racial employment gains. First-ever racial decomposition using QWI demographic breakdowns.
- **Data source:** Census QWI API (race/ethnicity table) — worked perfectly after switching from Azure (broken connection string) to direct API.
- **Key risk:** QWI cell suppression for small race-industry cells, especially Hispanic employment in small states.

## Execution
- **What worked:** Census QWI API with `time=from+to` range parameter returned all years in one call per state — reduced 39K API calls to 408. CS-DiD with `did` package ran smoothly after fixing numeric ID requirement.
- **What didn't:** Azure Blob Storage had truncated connection string (30 chars). Delhi GRAP idea failed entirely — all Indian air quality APIs inaccessible. Initial data fetch attempted one-year-at-a-time batching (state:*) which returned 400 errors.
- **Review feedback adopted:** Softened causal claims per GPT-5.4 advice. Added cell suppression caveat. Added JEL R58. Key unaddressed items for V2: event-study figures, county-level analysis, dose-response on credit generosity, formal cross-race tests.
