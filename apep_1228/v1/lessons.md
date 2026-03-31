## Discovery
- **Idea selected:** idea_2180 — GIPP waterbed effect using cross-insurer price-walking intensity
- **Data source:** Bank of England Insurance Aggregate Data (quarterly, 2017-2025) + FCA GI Value Measures (2021-2024)
- **Key risk:** Original firm-level continuous-treatment design was not feasible because FCA data has only banded categorical values, no direct renewal-to-new-business premium ratio

## Execution
- **What worked:** Pivoting to line-of-business DiD with BoE data gave 20 pre-periods and a clear pre-treatment window. The motor/property decomposition revealed a genuinely interesting finding. Firm-level data added the complaints mechanism.
- **What didn't:** The BoE file was mislabeled as CSV but was actually Excel. Property pre-trends are concerning (placebo p=0.052). With only 11 clusters and 3 treated lines, inference is inherently limited.
- **Review feedback adopted:** Toned down causal claims, reframed NWP as revenue not price, added inference caveats about small cluster count, acknowledged property pre-trend concern more prominently, added the caveat that aggregate data cannot definitively establish the claims-compression mechanism
- **Key lesson:** When the promised data structure doesn't support the proposed design, pivot early and honestly. The line-level DiD is weaker than the manifest's firm-level design but still tells an interesting story. Be transparent about what the design can and cannot identify.
