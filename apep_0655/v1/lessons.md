## Discovery
- **Idea selected:** idea_0263 — First employer-side evidence on immigration enforcement using administrative QWI data
- **Data source:** Census QWI from Azure (5M rows), SC activation dates from ICE FOIA PDF (3,186 jurisdictions)
- **Key risk:** Pre-trends in the Hispanic-NonHispanic employment differential

## Execution
- **What worked:** QWI data fetch from Azure was fast and reliable. FIPS matching for SC dates achieved 94.3% match rate. The DDD with county-ethnicity + county-quarter FE is computationally feasible even with 260K observations.
- **What didn't:** The positive DDD coefficient (Hispanic employment *increased* after SC activation) contradicts survey-based findings. Significant pre-trends complicate causal interpretation. The result likely reflects differential Hispanic formalization trends rather than enforcement effects. The earnings model failed with county-quarter FE due to singletons from NA values.
- **Review feedback adopted:** Added detrended specification (Hispanic × linear trend) per all 3 reviewers' concern about pre-trends — this eliminated the main effect entirely (0.180 → -0.019), converting the paper from a "positive enforcement effect" to an "honest null." Added QWI suppression discussion, 287(g)/E-Verify omission discussion, and referenced CS-DiD and HonestDiD as future directions. Updated abstract, results, discussion, and conclusion to reflect the null finding. The detrending was the most consequential change — it fundamentally changed the paper's interpretation.
