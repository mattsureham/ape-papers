## Discovery
- **Idea selected:** idea_0983 — Wales 20mph default speed limit. Clean cross-border natural experiment with STATS19 admin data.
- **Data source:** DfT STATS19 — 2019 data required historical master file (per-year file not available); 2020-2024 had individual year files.
- **Key risk:** Only 22 treated clusters; addressed with wild cluster bootstrap.

## Execution
- **What worked:** The combined 20+30mph outcome was the right approach — avoids mechanical reclassification artifact where "20mph casualties" surge and "30mph casualties" collapse due to relabeling.
- **What didn't:** Initial data fetch URLs were wrong — DfT changed URL patterns, and 2019 wasn't available as individual file. Had to use 1979-latest master file.
- **Review feedback adopted:** Added full event-study table (all reviewers asked for it), improved placebo discussion (addressed marginally significant high-speed coefficient), clarified border-pair interpretation.
