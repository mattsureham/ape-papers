## Discovery
- **Idea selected:** idea_0060 — State EITCs and industry reallocation of low-edu women (novel intensive-margin question)
- **Data source:** Census QWI on Azure Blob Storage — fast access via DuckDB, 123M rows aggregated to 245K state-year-industry-sex-edu cells
- **Key risk:** Null result (confirmed) — required compelling framing as informative null

## Execution
- **What worked:** Azure DuckDB pipeline for QWI data was fast and reliable. CS-DiD vs TWFE divergence became the methodological contribution — TWFE produces spurious 1.3pp healthcare effect that disappears with CS-DiD.
- **What didn't:** BigQuery API was disabled for the GCP project, requiring pivot from idea_0117 (patent examiners) to idea_0060. Also, loading Azure connection string via `source .env` only got 30 chars — had to use Python dotenv.
- **Review feedback adopted:** Added power/MDE discussion (both reviewers flagged), acknowledged county-to-state aggregation trade-off, fixed Wisconsin incorrectly listed as never-treated state. Reviewers wanted county-level robustness and policy confound controls — left for V2 revision.

## Key Insights
- Pre-2001 EITC adopters (14 states) have no pre-treatment QWI data — they contribute to cross-sectional but not event study variation. The 12 post-2001 adopters drive the event study.
- Null results need explicit confidence interval framing: "we can rule out X" is more informative than "we find zero."
- The TWFE vs CS-DiD divergence is a genuine teaching moment — worth centering in the narrative.
