## Discovery
- **Idea selected:** idea_0132 — Close-election RDD for female mayors and fiscal composition in Mexico. Clean identification, large election database, novel developing-country context extending Ferreira & Gyourko (2014).
- **Data source:** emagar/elecRetrns (GitHub) + INEGI EFIPEM (direct download). EFIPEM download required curl with extended timeout (108MB zip). Both sources worked well.
- **Key risk:** Runner-up gender not directly observed; had to be inferred from names. This was the largest methodological weakness and consumed significant development time.

## Execution
- **What worked:** RDD design was clean — McCrary test passed (p=0.15), most covariates balanced, results robust across bandwidths and donut specifications. The null result for social transfers was well-powered (MDE = 0.74 SD).
- **What didn't:** Pre-election payroll imbalance (p<0.01) required additional covariate-adjusted specifications to address. Name-based gender classification was conservative, dropping many races with ambiguous names. Sample shrank from manifest's promised ~3,946 to 468 — a gap all reviewers flagged.
- **Review feedback adopted:** (1) Expanded sample attrition explanation in Data section, (2) Added covariate-adjusted RDD and change specification for payroll to directly confront pre-period imbalance, (3) Added minimum detectable effects discussion for power assessment, (4) Added these results to robustness table. Single edit pass, one recompile.

## Key Takeaways
- For RDD papers, always run covariate balance tests early and have a plan for imbalanced covariates before writing the paper.
- Name-based gender classification in non-English contexts needs extensive dictionaries — start with 300+ names, not 50.
- When the manifest promises a much larger sample than what materializes, explain the attrition transparently in the paper.
