## Discovery
- **Idea selected:** idea_2147 — FCA price-walking ban is a clean natural experiment with public data and zero APEP coverage
- **Data source:** FCA Aggregate Complaints Data (Excel, fca.org.uk) + BoE Insurance Aggregate CSV — both fully public, no API keys needed
- **Key risk:** Few treated units (2 product lines) mean conservative inference may not reject null despite economically large effects

## Execution
- **What worked:** Cross-product DiD with simple TWFE — clean design, transparent assumptions, easy to explain
- **What didn't:** Pre-trend in early periods (2016-2018) suggests treated products were converging toward controls before the reform. Not fatal but complicates causal interpretation.
- **Data surprise:** FCA file naming conventions changed across publication years; 2021 H1 standalone file doesn't exist; required combining two publications with overlapping coverage
- **Review feedback adopted:** Toned down significance language (bootstrap/RI don't reject), added control-group decomposition showing the DiD is driven by controls surging (+34%) not just treated declining (-12%), qualified the "55% reduction" framing
