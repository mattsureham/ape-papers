## Discovery
- **Idea selected:** idea_1073 — Colombia's estrato boundaries create massive educational discontinuities, testable with 7.1M student records and built-in placebo
- **Data source:** ICFES Saber 11 via datos.gov.co SODA API — worked well but required city×period batching to avoid timeouts; manzana estrato from Esri Colombia ArcGIS
- **Key risk:** Spatial RDD required GIS processing that was too complex for V1; simplified to discrete boundary comparison

## Execution
- **What worked:** The multi-cutoff design with built-in 5|6 placebo. Clean null at the placebo boundary strongly supports the subsidy channel mechanism. The private vs. public school decomposition was an unexpected insight.
- **What didn't:** The discrete running variable weakened the causal interpretation compared to a true spatial RDD with geographic distance. All three reviewers flagged this. Few-cluster inference (5 municipalities) is a real limitation.
- **Review feedback adopted:** Re-framed design as "boundary comparison" not RDD; acknowledged few-cluster limitation; toned down causal language; fixed sample size inconsistencies. Deferred spatial RDD implementation to V2.
