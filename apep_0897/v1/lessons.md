## Discovery
- **Idea selected:** idea_1775 — Carboniferous Lottery (coal seam depth as IV for surface mining)
- **Data source:** MSHA mines + production (bulk), Water Quality Portal (REST API), Census ACS
- **Key risk:** Instrument is a proxy (historical mine share) rather than direct geological measurement (seam depth)

## Execution
- **What worked:** MSHA data was comprehensive (33K mines, 290K production records). WQP provided 784K conductance measurements across 7 states. The first stage is strong (F=34 without state FE).
- **What didn't:** USGS NCRDS drill-hole depth data was not accessible via API, forcing use of historical mine-type share as a proxy instrument. WQP required chunked 5-year requests to avoid timeouts. 7-state clustering produced non-positive-definite VCOV matrices. Alabama WQP consistently timed out on full date range.
- **Review feedback adopted:** Honest framing of instrument limitations (proxy vs direct geology), explicit caveats about legacy contamination as exclusion threat, tightened LATE interpretation, expanded limitations section acknowledging watershed-level mismatch and need for direct seam-depth data in future work.
