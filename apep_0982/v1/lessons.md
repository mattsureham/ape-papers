## Discovery
- **Idea selected:** idea_1632 — permitless carry and racial employment disparities in accommodation
- **Data source:** Census QWI (LEHD) bulk download from lehd.ces.census.gov — Azure had credential issues, Census API doesn't support wildcard state queries, LEHD bulk CSV worked perfectly
- **Key risk:** QWI race data has A0/A1/A2 ethnicity subcategories that MUST be handled carefully to avoid triple-counting

## Execution
- **What worked:** DDD design (state × race × sector) isolates a sharp result (-0.072) even when the direct CS-DiD shows no effect. The triple-difference is the right tool when the mechanism is race × sector specific.
- **What didn't:** State-level aggregation is too coarse for mechanism tests. County-level Black employment in accommodation is heavily QWI-suppressed, making the manifest's original county-tourism design infeasible.
- **Critical data bug:** QWI rh data has three ethnicity rows per race (A0=all, A1=non-Hispanic, A2=Hispanic). Summing across them triples employment counts. Also, Emp is a stock (beginning-of-quarter) that should be averaged, not summed, across quarters.
- **Review feedback adopted:**
  - Fixed data magnitudes (ethnicity filtering + mean vs sum)
  - Reframed result as relative sectoral reallocation, not absolute job loss
  - Acknowledged manufacturing as imperfect control sector
  - More honest about CS-DiD vs DDD divergence
