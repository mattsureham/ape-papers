## Discovery
- **Idea selected:** idea_0811 — Bartik IV using STEM degree expansion to study local tech sector dynamics. Chose for feasibility (both datasets on Azure), novelty (labor supply vs R&D channel), and first-order policy relevance.
- **Data source:** IPEDS DuckDB (Azure) + QWI Parquet (Azure) — Azure DuckDB ATTACH doesn't work remotely; downloaded 1.2GB file locally. QWI Parquet reads smoothly.
- **Key risk:** Weak first stage (F=6.4) due to fixed effects absorbing cross-sectional variation. Mitigated by strong reduced form.

## Execution
- **What worked:** Bartik IV structure, clean placebo, stable LOO and alternative base-year estimates. The "retention dividend" framing (reduced job destruction, not increased creation) is distinctive.
- **What didn't:** First-stage F below Stock-Yogo threshold despite strong unconditional correlation. Azure connection string parsing issues in R (semicolons as SQL delimiters).
- **Review feedback adopted:** Toned down multiplier interpretation, expanded weak-IV discussion, added multiple interpretations for BA+ share decline. Reviewers suggested additional placebos and LIML — deferred to V2 scope.
