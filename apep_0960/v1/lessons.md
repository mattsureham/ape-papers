## Discovery
- **Idea selected:** idea_0175 — Zambia's 2019 confiscatory mining tax reform, chosen for sharp timing and dramatic policy shock
- **Data source:** NASA VIIRS Black Marble VNP46A4 via earthaccess + GADM boundaries + FRED copper prices
- **Key risk:** Few treated clusters (11 mining districts); mitigated by broadening to 21 mining-province districts

## Execution
- **What worked:** earthaccess Python library for NASA data download (blackmarbler R package failed on HDF5 URLs); sf spatial join for pixel-to-district aggregation
- **What didn't:** blackmarbler R package couldn't download files (URL construction error returned HTML instead of HDF5); annual VIIRS data is coarse for a 9-month treatment window
- **Review feedback adopted:** Added discussion of pre-trend limitations, noted sensitivity of district-trends specification (-0.055), acknowledged unvalidated first stage (no direct mine production data)
