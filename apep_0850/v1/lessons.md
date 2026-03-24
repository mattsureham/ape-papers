## Discovery
- **Idea selected:** idea_1313 — Geneva minimum wage and cross-border worker composition. Vivid framing (world's highest MW), massive admin dataset (11.5M rows), novel question (cross-border labor composition, not domestic employment).
- **Data source:** BFS Grenzgängerstatistik via SDMX — download was straightforward but 1.2GB uncompressed (larger than the 523MB cited in the manifest). Data quality excellent: quarterly, canton × sector × country, back to 2002.
- **Key risk:** Single-treated-canton problem. Addressed via sector-level bite variation (triple-diff) and Ticino replication.

## Execution
- **What worked:** Triple-diff design with saturated FE absorbed canton-wide and sector-wide shocks cleanly. The 2015+ pre-period restriction was essential — pre-2015 data contaminated by AFMP adjustment and franc shock. Swiss data quality is exceptional.
- **What didn't:** Initial analysis included Vaud as a control — a critical error caught by reviewers. Vaud adopted its own cantonal minimum wage in Sep 2020. This contamination was driving the spurious placebo-timing result. Always verify that control units are truly untreated.
- **Review feedback adopted:** (1) Excluded Vaud from controls — the most impactful change. (2) Added permutation test (placebo-in-space). (3) Elevated hours-vs-heads limitation from Discussion to a primary caveat. (4) Added Vaud's own minimum wage to institutional background. (5) Revised power discussion to be more honest about MDE.
