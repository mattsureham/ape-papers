## Discovery
- **Idea selected:** idea_1981 — Wind turbines × bird populations via eBird/GBIF
- **Data source:** USGS WTDB (direct CSV, instant), GBIF eBird API (state-year queries, ~5 min)
- **Key risk:** State-level aggregation attenuates local ecological effects
- **Original idea (idea_0210, Ghana galamsey ban):** Failed due to ACLED API migration, BigQuery credential gap, and VIIRS HDF5/GDAL incompatibility. Three independent data access failures.

## Execution
- **What worked:** USGS WTDB download was flawless — clean CSV with 72K turbines. GBIF occurrence search API (not count API) returned state-year bird counts reliably. The fixest event study ran cleanly.
- **What didn't:** GBIF count endpoint doesn't support stateProvince filter (silent failure returning 0). Grasshopper Sparrow taxon key returned 0 records at state level. Had to remove grassland species from analysis.
- **Review feedback adopted:** Added power analysis paragraph discussing aggregation attenuation. Expanded limitations section to address ratio confound concern. Added Katovich benchmark comparison.
- **API lesson:** GBIF occurrence/search?limit=0 is the correct endpoint for filtered counts (not occurrence/count which only supports country+taxon).
