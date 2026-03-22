## Discovery
- **Idea selected:** idea_1634 — Time zone boundaries and teen morning traffic deaths. Chose for vivid mechanism ("the clock kills teenagers"), sharp spatial RDD at permanent boundaries, and free geocoded FARS data.
- **Data source:** NHTSA FARS (2010-2023) — excellent geocoding (98.9%), required fixing tempdir extraction bug in download loop
- **Key risk:** Sample size for teen-specific analysis near boundaries

## Execution
- **What worked:** FARS data download (after bug fix), spatial RDD at TZ boundaries with rdrobust, clean McCrary test (p=0.99), strong covariate balance
- **What didn't:** Teen-specific RDD is severely underpowered (MDE = 118% of baseline). The county-level aggregation (161 counties, 24 effective) is far too noisy — crash-level is the sharper specification
- **Review feedback adopted:** Added teen-specific crash-level RDD results to Table 2, added MDE/power calculations, restructured main table to lead with crash-level (not county-level) estimates, acknowledged teen power limitation explicitly in Discussion

## Key Lessons
- The manifest sets reviewer expectations — don't promise age-specific analysis without delivering it in tables
- Null results need MDE calculations to be credible — "hard null" vs "imprecise zero" distinction matters
- Crash-level spatial RDD with geocoded data is much sharper than county-level aggregation
- Time zone boundaries are a clean natural experiment but fatal crashes near boundaries are sparse for subgroup analysis
