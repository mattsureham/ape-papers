## Discovery
- **Idea selected:** idea_0055 — Recreational marijuana legalization and labor market firm dynamics via QWI
- **Data source:** Azure QWI Parquet files — worked well, 81K state-quarter-industry rows
- **Key risk:** State-level identification too coarse; reviewers flagged healthcare placebo as confound

## Execution
- **What worked:** Azure data pipeline fast and reliable; CS-DiD on balanced panel converged cleanly; pre-trends clean (p=0.43); LOO very stable
- **What didn't:** CS-DiD fails on unbalanced industry-level panels — had to fall back to TWFE for industry decomposition. QWI `geo_level` filter needed (county vs state data mixed). `did` package requires numeric (not integer) g_time for never-treated Inf assignment. 5 states dropped for balance reduces treated count from 23 to 18.
- **Review feedback adopted:** Softened firm dynamics claims (gross reallocation, not entry/exit); added honest healthcare placebo discussion (Medicaid expansion); clarified sample inconsistencies (24 vs 23 vs 18); flagged county-level border design as the logical next step; toned down conclusion
- **Key lesson:** State-level DiD with 18 treated units and a significant placebo outcome is a weak design. The QWI data has county-level granularity that would make a much stronger paper. Idea was oversold at state level.
