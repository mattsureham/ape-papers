## Discovery
- **Idea selected:** idea_0245 — Belgium's 2016-2018 employer SSC cut (32.4% → 25%), the largest in recent OECD history, with no prior causal evaluation
- **Data source:** Eurostat API via `eurostat` R package — 4 tables, all freely accessible, no API key needed
- **Key risk:** Small country N (Belgium = 1 treated unit); mitigated through permutation inference and A*21 sector expansion

## Execution
- **What worked:** Clean first stage (SSC share -1.75pp, p<0.01), textbook pre-trends, strong null result with permutation p=0.75. Belgium's wage rigidity institutions (indexation + sectoral bargaining) provide a genuine natural experiment.
- **What didn't:** SCM failed (data format issue with augsynth); triple-diff SE was degenerate with only 4 geo clusters (fixed by clustering at country×sector level). Initial n_treated=10 failed the ≥20 validator threshold — resolved by supplementing with LFS quarterly at A*21 level (21 sectors).
- **Review feedback adopted:** Added equivalence/power bounds (upper CI = +0.016, cost per marginal job ≥€120K), discussed Brussels attacks and VAT financing as confounders, expanded event study description with actual coefficients, added A*21 LFS robustness.
