## Discovery
- **Idea selected:** idea_1794 — Nebraska NRD groundwater allocations, staggered DiD on crop composition
- **Data source:** USDA NASS Quick Stats API — worked well, 35K observations fetched. Farm income endpoint returned 400 error (bad query format for county-level income).
- **Key risk:** Small groups (2-5 counties per NRD) → singular covariance in CS, preventing event study SEs. Mitigated with TWFE event study.

## Execution
- **What worked:** The corn lock-in finding — opposite of the naive expectation — is a genuine contribution. NASS API delivered clean data. NRD-to-county crosswalk was straightforward. The soybean placebo (null, p=0.67) strengthens the mechanism story.
- **What didn't:** CS estimator's singular covariance matrix prevented proper event study inference and HonestDiD bounds. Pre-1990 data extended to 1988 to satisfy 5+ pre-period requirement. Farm income API failed.
- **Review feedback adopted:** Added TWFE event study with cluster-robust SEs (addressing all 3 reviewers' primary complaint). Added caveats about binary treatment and irrigated/non-irrigated data. Deferred dose-response and irrigated-specific analysis to potential V2.
