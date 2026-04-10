## Discovery
- **Idea selected:** idea_2016 — Mexico's 2023 vacation reform doubling formal workers' leave. Chosen for the informality margin angle: most vacation studies are in formal economies; Mexico's 57% informality creates a natural control.
- **Data source:** INEGI ENOE quarterly microdata — freely downloadable but tricky URL patterns (changed 3× across ENOE/ENOEN/ENOE). Total ~900MB across 21 ZIPs.
- **Key risk:** Concurrent minimum wage increases could confound the DiD; mitigated by seniority dose variation and the fact that MW affects both sectors.

## Execution
- **What worked:** The DiD with formal vs. informal is clean. 4.8M observations give tremendous power. The event study is visually compelling (flat as a pancake). The null result is genuinely informative.
- **What didn't:** (1) ENOE variable coding was initially wrong — `seg_soc = 2` means "no social security," not "has." Gave 96% formality rate. Always check ENOE dictionaries. (2) Data combination OOMed on a 16GB machine with all 22 quarters loaded. Fixed by selecting columns first. (3) 2019 ENOE ZIPs have nested `catalogos/` directories whose CSV files pollute naive grep matching.
- **Review feedback adopted:** Added MDE language, addressed the marginally significant placebo test, clarified the formality regression is pre-post not DiD, added mechanism discussion, strengthened wage result caveat.
