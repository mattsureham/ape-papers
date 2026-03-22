## Discovery
- **Idea selected:** idea_0578 — France QPV spatial RDD, chosen for massive internal replication (1,372 boundaries), freely available DVF data, and vivid stigma-vs-subsidy puzzle
- **Data source:** DVF geolocalized (data.gouv.fr) + QPV boundaries (Geoplateforme WFS). Data.gouv.fr URLs from the idea manifest were stale; had to discover the WFS endpoint via capabilities query.
- **Key risk:** Covariate imbalance at the QPV boundary (QPVs are designated based on income, which correlates with housing characteristics)

## Execution
- **What worked:** Optimized spatial distance computation by using QPV union boundary (single geometry) instead of per-QPV boundary computation. This reduced processing time from hours to minutes for 1.8M transactions. The MSE-optimal bandwidth of 110m provided a clean estimate.
- **What didn't:** DVF geolocalized data only available 2020-2024, not 2014+ as the idea manifest suggested. Lost the pre-treatment placebo. The donut hole test was implausible (MSE-optimal bandwidth of 110m means excluding 50m removes half the effective sample).
- **Review feedback adopted:** Softened "stigma" interpretation to acknowledge multiple channels; noted 300m VAT buffer contaminates control group; removed implausible donut estimate; expanded limitations with four explicit concerns.
