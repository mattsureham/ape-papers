## Discovery
- **Idea selected:** idea_1459 — "Insured Escape" (1935 SSA exclusion and Black occupational sorting)
- **Data source:** MLP Linked Panel (Azure, ~5GB) — required DuckDB-side processing to avoid R memory issues
- **Key risk:** Only 2 time periods (decennial census), limiting pre-trend validation

## Execution
- **What worked:** Doing all heavy SQL in DuckDB and pulling only the analysis-ready panel into R. The occupation-type decomposition (domestic vs. agriculture) turned a marginal aggregate result into a compelling mechanism test. Azure connection required fixing a semicolon-in-connection-string parsing bug.
- **What didn't:** First attempt loaded 10M rows into R memory, causing a 7.7GB stuck process. State×decade FE on the full 18M panel also hit memory limits.
- **Review feedback adopted:** Toned down "stark" framing, added footnote explaining smoke-test discrepancy, strengthened threats-to-validity discussion with explicit treatment of baseline gaps and linkage quality.
