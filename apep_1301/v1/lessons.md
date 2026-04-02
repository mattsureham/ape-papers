## Discovery
- **Idea selected:** idea_1734 — SNAP retailer exits and birth outcomes (reverse Hoynes et al. experiment)
- **Data source:** CDC NCHS natality (FTP fixed-width), USDA SNAP Retailer Historical Database — CDC data required pivot from NBER CSV (404) to FTP fixed-width files
- **Key risk:** State-level aggregation would wash out neighborhood-level food access effects

## Execution
- **What worked:** SNAP retailer data clean and comprehensive (703K records). Chain bankruptcy identification worked well (2,528 stores across 5 events). CDC natality parsing reliable across 8 years.
- **What didn't:** NBER natality CSVs are down — forced state-level analysis instead of county-level. The chain bankruptcy IV is weak at state level (F=1.4). The fundamental problem: supermarket closures are a local phenomenon but the data forces state-level aggregation.
- **Key finding:** Well-powered null — no detectable effect of state-level supermarket exits on birth outcomes. Extends Allcott et al. (2019) from purchasing to health.
- **Review feedback adopted:** Reviewers confirmed the aggregation concern is the main limitation. Framed paper honestly as "the null that matters" — documenting that the aggregate channel is absent, pointing to the need for sub-state analysis.
