## Discovery
- **Idea selected:** idea_1056 — India's IAP combined security-development program with 60 sharply designated districts and 18 years of pre-treatment nightlights
- **Data source:** SHRUG v2.1 DMSP nightlights — already on disk, no API calls needed. Census 2011 district directory downloaded from GitHub.
- **Key risk:** Pre-existing convergence in IAP districts could contaminate the DiD estimate

## Execution
- **What worked:** District-specific linear trends specification successfully absorbed convergence; validated by placebo test (2005 placebo yields zero with trends, significant without)
- **What didn't:** Census 2001/2011 DiD failed due to district ID scheme mismatch between census waves; boundary DiD and RDD from the manifest were not implemented due to V1 scope
- **Review feedback adopted:** Added placebo-with-trends validation (strongest addition), noted state-level clustering significance (p=0.034), acknowledged boundary DiD/RDD as future work
