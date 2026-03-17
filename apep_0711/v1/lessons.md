## Discovery
- **Idea selected:** idea_0162 — Online sports betting legalization and suicide mortality (pivoted from idea_0045 Kenya pension RDD due to DHS data access failure)
- **Data source:** CDC Early Model-Based Provisional Estimates (v2g4-wqg2) — free API, no credentials needed
- **Key risk:** Small treated cluster count (10 states); model-based estimates may attenuate effects

## Execution
- **What worked:** CDC Socrata API delivered 15,555 suicide rows instantly; CS-DiD + TWFE + RI all converge on a precise null; pre-COVID subsample provides a provocative contrast
- **What didn't:** Transport death placebo unavailable from this CDC endpoint; initial week-parsing bug (grabbed datetime column instead of MMWR week integer) caused all observations to appear post-treatment; CS-DiD on weekly data fails due to extreme panel imbalance — monthly aggregation required
- **Review feedback adopted:** Fixed inconsistent treated state counts (14→11→10 pipeline now documented throughout); added MDE/power paragraph quantifying that clinical prior (~0.2 deaths) falls within CI; clarified WV/NH/WY suppression in all tables
