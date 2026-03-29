## Discovery
- **Idea selected:** idea_1902 — "Does Crop Insurance Save Lives?" Chose for first-order stakes (mortality), massive sample (51K county-years), and memorable mechanism name ("despair insurance")
- **Data source:** CDC NCHS model-based estimates (rpvx-m2md), USDA RMA Summary of Business, NOAA PDSI — all public, no keys needed. RMA URL was tricky: old URLs dead, new ones at pubfs-rma.fpac.usda.gov
- **Key risk:** Exclusion restriction for weather IV — drought might affect deaths through non-income channels

## Execution
- **What worked:** Division-level PDSI gave a strong first stage (F=12.0), much better than state-level (F=2.1). The NOAA county-to-climate-division crosswalk was the critical fix. Three data sources merged cleanly to 51K obs.
- **What didn't:** The hypothesis didn't hold — the reduced form is null. But this became the paper's strength when framed as a well-powered null.
- **Review feedback adopted:** Added Anderson-Rubin weak-IV-robust CI, strengthened exclusion restriction defense with temperature discussion, added transmission mechanism limitation, softened policy conclusion scope
