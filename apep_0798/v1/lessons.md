## Discovery
- **Idea selected:** idea_1048 — FASTag electronic toll mandate, chosen for sharp treatment timing, 700+ geocoded plazas, and vivid "does digitizing infrastructure generate spillovers?" question
- **Data source:** Toll plazas from GitHub (geohacker/toll-plazas-india), Google Community Mobility Reports for district-level outcomes
- **Key risk:** COVID recovery confound; addressed via state × week FE

## Execution
- **What worked:** Google Mobility data proved to be an excellent high-frequency, district-level outcome covering the exact mandate window (Feb 2020 – Oct 2022). The DiD design with 270 treated + 361 control districts and 143 weeks is well-powered.
- **What didn't:** The toll plaza "traffic_per_day" field is static (design capacity, not actual traffic), killing the original plaza-level event study. VIIRS nightlights download failed (HDF5 driver issues with blackmarbler, bad URLs for NOAA direct download). First idea choice (idea_1047) was already claimed; second choice (idea_0614, California QME) failed due to data access requiring PRA/DUA.
- **Critical lesson:** Always check whether "traffic data" in scraped government portals is actual time-varying traffic vs. a static capacity parameter. The field was labeled "traffic_per_day" but was constant across 47 snapshots.
- **Review feedback adopted:** Awaiting reviews.
