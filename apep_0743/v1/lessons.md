## Discovery
- **Idea selected:** idea_1684 — Funeral director mandates and death care markets. Chosen for sharp border discontinuity design (26 segments), novel application to occupational licensing literature, and confirmed CBP API access.
- **Data source:** Census County Business Patterns (NAICS 812210, 812220), ACS 5-year, Census Gazetteer. CBP API worked for 2017-2022 but not pre-2017 (NAICS code parameter changed).
- **Key risk:** Power — the design turned out to have MDE of ~43% of mean, too large to detect the moderate effects predicted by licensing theory.

## Execution
- **What worked:** The border-pair construction via Gazetteer centroids and Haversine distance was clean and reproducible. 800 county pairs across 26 segments gave good coverage. The null result is well-powered for large effects and tells a clear story.
- **What didn't:** Pre-2017 CBP data was inaccessible via the current API endpoint, limiting us to 6 years averaged into a cross-section. This is the biggest weakness — all three reviewers flagged it. County adjacency file was also 404, requiring the Gazetteer workaround.
- **Review feedback adopted:** Toned down MDE claims (can't rule out 10-20% effects), added explicit discussion of population imbalance (marginally significant), strengthened caveat about payroll-as-price-proxy, acknowledged cross-sectional limitation.
