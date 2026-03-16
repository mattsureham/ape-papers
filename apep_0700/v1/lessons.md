## Discovery
- **Idea selected:** idea_0889 — UK LHA freeze creating differential LHA-rent gaps across 152 BRMAs, effects on homelessness
- **Data source:** MHCLG Table 784a (quarterly homelessness), VOA/Cambridgeshire Insight (LHA rates), NOMIS (controls)
- **Key risk:** Pre-trends in TA rates — areas with faster rent growth already had rising TA before the freeze

## Execution
- **What worked:** The LHA rates CSV from Cambridgeshire Insight is a clean, well-structured dataset with 152 BRMAs × 10 years. The continuous DiD design exploiting the 0-39% gap range produces a highly significant TA result (p < 0.001) that is robust across specifications.
- **What didn't:** The BRMA-to-LA mapping was the biggest challenge. No published crosswalk exists; had to construct one using spatial centroids + postcodes.io reverse geocoding. Only 130/326 LAs could be cleanly mapped, reducing the sample. A proper spatial overlay with both boundary polygons would improve coverage.
- **Pre-trend concern:** Both reviewers flagged the significant pre-trend (gap × trend = 0.093, p = 0.003) in TA rates. This is the main limitation — the estimate is an upper bound. For v2, consider LA-specific linear trends or matching on pre-trends.
- **Review feedback adopted:** (1) Clarified treatment variable as "exposure design" using eventual gap rather than implying time-varying treatment. (2) Added sample selection discussion comparing included vs excluded LAs. (3) Strengthened pre-trend framing as upper bound.
- **Surprising finding:** The acceptance rate DECLINED slightly while TA rose — consistent with compositional shifts from prevention to emergency placement. This is an interesting institutional finding about how benefit erosion changes the structure of homelessness responses.
