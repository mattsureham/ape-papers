## Discovery
- **Idea selected:** idea_0118 — Medicaid expansion and job lock via QWI firm dynamics
- **Data source:** Census QWI on Azure Blob (Parquet via DuckDB) — smooth, fast query (~197K rows in seconds)
- **Key risk:** Education placebo doesn't cleanly separate — high-edu workers also show significant DDD effects

## Execution
- **What worked:** DDD design with three-way FE produces clean estimates; pre-trend test passes; dose-response pattern consistent with mechanism; QWI data perfectly suited for worker-flow analysis
- **What didn't:** Callaway-Sant'Anna event study failed on unbalanced panel — switched to Sun-Abraham via fixest::sunab() which worked but showed noisy pre-trends; education-level "quadruple difference" doesn't work as a clean placebo
- **Review feedback adopted:** TBD (reviews in progress)

## Key Numbers
- DDD hire rate: +0.691 (SE=0.282, p=0.018)
- DDD separation rate: +0.668 (SE=0.323, p=0.044)
- Pre-trend: 0.015 (p=0.43) — clean
- Dose-response: high uninsured states 0.658 vs low 0.258
- 8,244 state×quarter×industry×education observations
- 34 treated states, 16 pre-periods
