## Discovery
- **Idea selected:** idea_1698 — Post-Dobbs reproductive healthcare labor reallocation via QWI
- **Data source:** Census QWI API — reliable, no rate limiting issues, required comma-separated FIPS codes (no wildcard support)
- **Key risk:** Few receiving-state clusters (9) for inference; null finding in ban states could be compositional

## Execution
- **What worked:** QWI data fetched cleanly in one pass (190/190 API calls). The triple-difference with dental placebo is the strongest identification. The receiving-state DDD is significant at 5%.
- **What didn't:** CS-DiD failed due to panel balancing issues; TWFE is justified since treatment is simultaneous. The ban-state null was unexpected but becomes the story.
- **Review feedback adopted:** Added pre-trends discussion, justified TWFE vs CS-DiD, acknowledged wild cluster bootstrap limitation, strengthened receiving-state definition rationale with Guttmacher citation.
