## Discovery
- **Idea selected:** idea_0997 — Ghana's mass MFI revocation (347 licenses) as natural experiment for financial intermediary destruction effects
- **Data source:** NASA Black Marble VNP46A4 (VIIRS nighttime lights), Bank of Ghana reports, GADM boundaries, Ghana Census
- **Key risk:** Pre-trends at t-5 and regional (not district) treatment assignment

## Execution
- **What worked:** VIIRS data pipeline via NASA CMR API + earthdatacloud direct download. Dose-response DiD with 16 regions × 10 years clean design. Randomization inference appropriate for few clusters.
- **What didn't:** blackmarbler R package failed (HDF5/GDAL issues). Had to build manual tile download + processing pipeline. Treatment variable limited to 16-region level (no district-level MFI locations available).
- **Review feedback adopted:** Added district-specific linear trends specification (effect reverses to +0.06), added MDE power discussion (can rule out >27% effects), toned down mobile money mechanism claims to "suggestive context not demonstrated mechanism", added COVID confounding caveat, acknowledged 16 effective treated units throughout.
