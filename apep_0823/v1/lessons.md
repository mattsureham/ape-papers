## Discovery
- **Idea selected:** idea_0947 — Alice Corp v. CLS Bank as natural experiment for software patent policy effects on labor markets
- **First idea failed:** idea_0944 (Swiss firm-size bunching) failed because public aggregate data doesn't split the 50-249 bin at 100 employees. Lesson: verify data resolution matches threshold placement before committing.
- **Data source:** Census CBP (annual county × NAICS) — pivoted from QWI (Azure connection issues) and BigQuery (first-stage only)
- **Key risk:** NAICS 511→518 structural reclassification from cloud computing transition

## Execution
- **What worked:** Clean DiD with strong first stage (patent rejection rates tripled). Event study shows flat pre-trends on restricted 2012-2019 sample. Industry heterogeneity tells a compelling value-chain story.
- **What didn't:** Azure blob storage connection failed (URL parsing issue). BLS QCEW API only goes back to 2014 for 3-digit NAICS. Had to fall back to annual CBP which reduces temporal precision.
- **Review feedback adopted:** Added discussion of NAICS reclassification concern, clarified CBP timing (March reference period vs June decision), noted CBP suppression as potential bias source.
