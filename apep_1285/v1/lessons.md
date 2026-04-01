## Discovery
- **Idea selected:** idea_1307 — AEOI shock to Swiss banking secrecy + real estate, chosen for sharp treatment date, novel question, and Swiss open-data advantage
- **Data source:** SNB regional real estate price indices (data.snb.ch API) — worked perfectly, 55 years of annual data
- **Key risk:** Only 8 regional clusters; addressed with permutation inference and leave-one-out analysis

## Execution
- **What worked:** SNB API returned clean data on first call. The null result was remarkably stable across all specifications. Permutation inference (p=0.782) and LOO both confirmed the null. The event study showed clean pre-trends.
- **What didn't:** Banking employment (NOGA 64) is an imperfect proxy for AEOI exposure. Reviewers correctly noted that SFTA voluntary disclosure counts or foreign-controlled bank data would be more direct measures. The t=0 spike at 2017 (significant but transient) was flagged by all three reviewers as needing deeper investigation.
- **Review feedback adopted:** Added MDE discussion (3.7pp minimum detectable effect), justified 8-vs-12 region sample, discussed measurement error attenuation, expanded macroprudential confound discussion, wrote three candidate interpretations for t=0 spike. Did not add SFTA data or German placebo (V2 candidates).
