## Discovery
- **Idea selected:** idea_0957 — UK freeports, first causal evaluation (IFS noted gap)
- **Initial idea failed:** idea_0153 (Universal Free School Meals) — SEDA 2024 data URL returns 404, EdFacts only through 2018. Always verify data URLs before committing.
- **Data source:** Companies House bulk CSV (468MB, 5.7M companies) + ONS NSPL via ArcGIS FeatureServer
- **Key risk:** Small number of treated LAs (21) limits statistical power

## Execution
- **What worked:** Companies House data is excellent — complete universe, monthly frequency, SIC codes for sector decomposition. ONS ArcGIS FeatureServer works for bulk postcode-to-LA lookup (paginated with ObjectId).
- **What didn't:** Geocoding 852K postcodes via postcodes.io API was too slow (~70 min). The ArcGIS paginated download also had issues (stopped at 75%). Solution: two-pass approach (direct NSPL match + outward-code majority match) achieved 84% coverage.
- **Key finding:** Null result — CS-DiD ATT = 0.026 (SE 0.031). Adjacent LAs show suggestive negative displacement (-0.044). TWFE vs CS-DiD discrepancy confirmed standard contamination bias.
- **Review feedback adopted:** Added dilution bias caveat (tax sites small within LAs), MDE discussion (~6% minimum detectable), fixed data inconsistency (3.3M vs 4.2M).
