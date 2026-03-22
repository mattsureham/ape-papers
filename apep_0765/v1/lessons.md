## Discovery
- **Idea selected:** idea_1736 — Grocery exit and mortgage markets. Novel cross-domain link no one has tested.
- **Data source:** CFPB HMDA API (30.9M loan-level records, state-by-state download) + SNAP retailer database.
- **Key risk:** HMDA download time (51 states × 6 years = ~40 min for 306 API calls)

## Execution
- **What worked:** CFPB API returned clean data with census_tract field. 30.9M loans aggregated to 19K county-year obs. County-level merge with SNAP was straightforward using FIPS crosswalk (96.1% match).
- **What didn't:** Had to aggregate to county level (not tract) because SNAP data lacks tract FIPS without geocoding. This is coarser than ideal but sufficient for a V1.
- **Key finding:** Clean null across all four outcomes. Supermarket exit has no detectable effect on originations (+0.3%), denial rates (-0.2 pp), loan amounts, or FHA share. Confidence intervals are tight enough to rule out economically meaningful effects. The capital market does not treat grocery exit as a lending signal.
- **Review feedback adopted:** [pending]
