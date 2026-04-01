## Discovery
- **Idea selected:** idea_0645 — BLM lottery leases as exogenous variation in extraction timing; chosen for genuine randomization at scale (118K leases) and first-order resource curse question
- **Data source:** BLM MLRS bulk CSV (300MB, 3.1M records) + BEA REIS county panel. BLM ArcGIS API decommissioned; had to use GBP Hub download. PLSS geocoding required careful handling (4-digit township format).
- **Key risk:** County-level aggregation may attenuate the parcel-level first stage documented by Brehm (2021)

## Execution
- **What worked:** Spatial join via R's sf + tigris mapped 99.2% of townships to counties. Good cross-county variation in lottery share (mean 0.38, SD 0.29). Well-powered null result robust across all specifications.
- **What didn't:** Missing county-level first stage (no drilling/spud data to show lottery share actually delays aggregate extraction). Pre-period coefficients overlap with the treatment era, complicating pre-trend interpretation. 13 state clusters is tight for inference.
- **Review feedback adopted:** Added wild cluster bootstrap (p = 0.40), minimum detectable effect (8.7%), explicit first-stage limitation, clarified pre-trend overlap with treatment era, softened overclaiming language.
