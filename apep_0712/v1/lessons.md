## Discovery
- **Idea selected:** idea_1018 — UK ground rent abolition, temporal RDD at June 30, 2022. Chosen for clean data (Land Registry PPD bulk CSV), sharp cutoff, and multiple identification strategies.
- **Data source:** HM Land Registry PPD — 5M records downloaded instantly, no API keys. Best data access experience in APEP.
- **Key risk:** Concurrent housing market crash (Bank of England rate rises, Truss mini-budget) confounding the temporal RDD.

## Execution
- **What worked:** Land Registry data is extraordinarily clean. 87,444 new-build leasehold flat transactions, universe coverage. DiD and DDD ran smoothly. Geographic heterogeneity (London vs. rest) revealed a fascinating sign reversal.
- **What didn't:** The temporal RDD was completely confounded by the market crash. Density test failed (t=-14.3), placebo cutoffs significant, freehold placebo significant. Triple-diff had collinearity with ym FE — fixed by switching to year + quarter FE.
- **Review feedback adopted:** Added ITT framing, geographic heterogeneity, incidence discussion (who captured the surplus?), restructured abstract to lead with DiD rather than failed RDD. All three reviewers flagged the same core issues — shows strong consensus.

## Key Lesson
When a temporal RDD coincides with a major macroeconomic shock, the RDD is almost certainly invalid. The concurrent Bank of England tightening + Truss mini-budget created ~10% housing market decline that swamped any ground rent capitalization signal. DiD with a control group is essential in such settings, but the control group must face similar macro exposure — freehold houses may differ in rate sensitivity from leasehold flats. Future papers using UK housing data around 2022 should always test for differential macro exposure.
