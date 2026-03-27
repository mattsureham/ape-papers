## Discovery
- **Idea selected:** idea_0508 — EU Single-Use Plastics Directive, staggered transposition across 27 member states
- **Data source:** Eurostat env_waspac (packaging waste by material) + CELLAR SPARQL (transposition dates). Both fully open, no API keys needed.
- **Key risk:** Annual data granularity limits precision; COVID overlap with treatment window

## Execution
- **What worked:** CELLAR SPARQL transposition panel construction was clean — 161 national measures, clear staggered timing. Built-in placebo design (glass/metal packaging) validates the research design elegantly.
- **What didn't:** Eurostat R package column naming (`TIME_PERIOD` vs `time`) wasted debugging time. Pre-2019 legislation was spuriously linked to the SUP Directive in CELLAR — needed filtering.
- **Review feedback adopted:** All 3 reviewers flagged (1) need to quantify targeting mismatch, (2) event-time -1 concern, (3) packaging definition issue. Added 1-3% share estimate, expanded anticipation discussion, added weight-vs-count caveat. Deferred Comtrade trade data analysis to V2.
