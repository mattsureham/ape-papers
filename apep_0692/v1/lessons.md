## Discovery
- **Idea selected:** idea_0166 — E-Verify geographic spillovers via spatial DDD on QWI data
- **Data source:** LEHD QWI (direct download from lehd.ces.census.gov) — Azure connection failed, pivoted to direct LEHD bulk CSV download; ~50% of state files had truncated downloads but still parsed enough data
- **Key risk:** Few border counties (73) limiting precision in event studies

## Execution
- **What worked:** The DDD specification with county-ethnicity FE and quarter×ethnicity FE cleanly identifies the chilling effect. The professional services placebo (coefficient = 0.008, p = 0.93) is powerful internal validation.
- **What didn't:** Azure blob connection string failed (DuckDB Azure extension issue). Had to pivot to direct LEHD downloads, which were slow and ~30% truncated. Initial DDD specification had collinearity because `post` is zero for all interior counties — fixed by restructuring FEs.
- **Review feedback adopted:** Added event study discussion, expanded limitations (informal sector, cluster count), added level-interpretation of economic magnitude (1,470 fewer Hispanic workers per border county-quarter).
- **Surprise finding:** Expected displacement (positive spillover) but found the opposite — a chilling effect where employers near enforcement reduce Hispanic hiring preemptively. This reframing makes a stronger paper.
