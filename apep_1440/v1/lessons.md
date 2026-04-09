## Discovery
- **Idea selected:** idea_2297 — karst geology as instrument for PFAS contamination
- **Data source:** EPA UCMR5 (1.8M rows), USGS sinkhole susceptibility index (county-level)
- **Key risk:** Spatial resolution too coarse for the geological mechanism

## Execution
- **What worked:** Data linkage pipeline (UCMR5 → ZIP → county → karst) was clean. UCMR5 is an excellent dataset — 10K+ PWSs, 29 PFAS compounds, first national monitoring program.
- **What didn't:** USGS karst polygon shapefile (269MB, pubsdata.usgs.gov) was unreachable due to DNS failure, forcing pivot from spatial RDD to county-level OLS. This destroyed the identification strategy.
- **Review feedback adopted:** Added explicit acknowledgment of data constraint forcing design pivot; strengthened discussion of measurement error and MDE; noted the nonlinear (quadratic) result in main text. Reviewers correctly identified that county-level design cannot deliver the causal identification the idea promised.

## Key Takeaway
The karst/PFAS idea is excellent but requires well-level geological classification to work. County-level proxies are too coarse. Future work should access USGS OFR 2014-1156 shapefiles directly or use state geological survey data to classify individual wellheads.
