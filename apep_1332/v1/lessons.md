## Discovery
- **Idea selected:** idea_1989 — TMDL water quality, chosen for massive power (1M+ readings), built-in placebo, and first-order policy question
- **Data source:** EPA ATTAINS GIS + Water Quality Portal — ATTAINS REST API was down (500 errors); pivoted to ArcGIS REST service. WQP failed for state-wide queries; worked around by querying per-HUC8
- **Key risk:** TMDL approval dates unavailable → had to use 2022 snapshot cross-sectional treatment instead of staggered DiD

## Execution
- **What worked:** HUC8-by-HUC8 WQP fetching yielded 1.2M DO readings. ATTAINS GIS service reliable. Nearest-station matching for TMDL-to-HUC8 crosswalk. Clean placebo test.
- **What didn't:** ATTAINS REST API completely down. WQP state-wide queries broken (400 errors). rATTAINS R package incompatible with R version. Had to use 2022 snapshot instead of actual TMDL dates — reviewers flagged this as major limitation.
- **Review feedback adopted:** Tempered causal language about negative coefficient. Added explicit acknowledgment of temporal mismatch. Added selection-on-trends interpretation alongside paper-tiger mechanism. Acknowledged DO-only limitation vs. multi-pollutant design.
