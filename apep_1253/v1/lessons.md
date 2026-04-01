## Discovery
- **Idea selected:** idea_1758 — TFP revision + QWI labor reallocation. Selected for massive N (3,100 counties), QWI data on Azure, CBO gap, industry decomposition novelty.
- **Data source:** QWI via Azure (1.54M rows), SAIPE via Census API (3,142 counties)
- **Key risk:** October 2021 treatment date coincides with end of COVID recovery, enhanced UI expiration, and Great Resignation — confounding from pandemic recovery dynamics.

## Execution
- **What worked:** Azure data access (after fixing connection string truncation bug — bash semicolons). QWI panel construction was clean. 444K county-industry-quarter observations.
- **What didn't:** Pre-trends fail. Event study shows uniformly positive pre-treatment coefficients — high-poverty counties were on differential upward trajectory before TFP revision, likely from COVID recovery. Placebo test (2019Q4) also rejects (p=0.008). Finance sector shows strongest "effect" (-0.0057) which doesn't fit the SNAP story. Hires/separations decomposition shows null on both margins.
- **Review feedback adopted:** [pending — reviews in progress]

## Key Methodological Lesson
Evaluating safety net changes that coincide with macroeconomic inflection points (like the end of COVID recovery) requires sharper identification than continuous-treatment DiD on county poverty rates. The very counties most exposed to SNAP benefit increases are those whose labor markets were most disrupted by COVID. Future designs should use actual SNAP caseload data (not poverty proxy) or exploit staggered EA expiration for cleaner identification.
