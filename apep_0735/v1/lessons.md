## Discovery
- **Idea selected:** idea_1645 — France ABF 500m monument boundary spatial RDD. Chosen for sharp arbitrary threshold, massive internal replication (44K monuments), and genuinely ambiguous sign prediction.
- **Data source:** DVF (data.gouv.fr) + Monuments Historiques (data.culture.gouv.fr) — both fully open, no API keys needed. DVF bulk CSVs ~100MB/year. Monuments API caps offset at 10000; use bulk CSV export instead.
- **Key risk:** Overlapping monument zones in urban areas contaminate control group; continuous price gradient near monuments makes placebo cutoffs significant.

## Execution
- **What worked:** The heterogeneity decomposition (classé vs inscrit) is the paper's strongest finding. The sign reversal is difficult to explain by amenity gradients alone and directly tests the amenity-vs-restriction tradeoff.
- **What didn't:** The pooled RDD estimate is weaker than hoped — McCrary significant, several placebos significant, commune FE specification nullifies it. This is a spatial RDD where the "treatment" (regulatory intensity) is highly correlated with urban density and neighborhood desirability.
- **Review feedback adopted:** Added sections on overlapping zones, spatial correlation, and better reconciliation of parametric vs nonparametric results. Reframed the heterogeneity as the main contribution rather than the pooled estimate.
- **Future V2 opportunities:** (1) Sitadel construction permit data for supply-side mechanism test, (2) LCAP 2016 reform DiD for within-monument regulatory relaxation, (3) Restrict to isolated monuments (>1km from any other) for cleaner identification.
