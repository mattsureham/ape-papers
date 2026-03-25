## Discovery
- **Idea selected:** idea_0503 — EU EECC staggered transposition across 27 member states as natural experiment for telecom prices
- **Data source:** Eurostat HICP CP08 (communications CPI) via direct JSON API — the `eurostat` R package filter approach failed; needed repeated `&geo=` params
- **Key risk:** Pre-existing secular trends in telecom prices could confound — and they did

## Execution
- **What worked:** The Eurostat API delivered clean, complete data (319 obs, 29 countries). CS-DiD implementation was straightforward. The methodological story — TWFE overstating by 6x, failed placebos, sign-heterogeneity across cohorts — was compelling and well-supported by diagnostics.
- **What didn't:** The original hypothesis (EECC reduces prices) was wrong. Pre-trends failed decisively, and placebos (food +8.3***, housing -6.4***) confirmed endogenous timing. Had to pivot from "cost of delay" to "transposition mirage" framing.
- **Review feedback adopted:** Added power caveat (MDE conditional on valid PT), clarified never-treated group definition, added direct endogenous timing test (transposition year ~ pre-treatment price trends), strengthened the methodological framing per reviewer suggestions.
