## Discovery
- **Idea selected:** idea_0590 — MCMV housing lottery and school quality. Strongest identification in the random draw (lottery design, massive scale).
- **Data source:** INEP IDEB direct downloads + Ministry of Cities open data portal (gov.br/cidades). BigQuery was unavailable.
- **Key risk:** Only 2 pre-treatment IDEB waves for earliest cohort (biennial data). Later cohorts have more.

## Execution
- **What worked:** Direct INEP downloads are excellent — single xlsx contains all 10 IDEB waves. MCMV OGU data from gov.br/cidades is clean and comprehensive. CS estimator handled the staggered design well.
- **What didn't:** Municipality-level aggregation dilutes the local school-quality effect. School-level geocoded analysis (as in the original idea) would be much stronger. The "absorption illusion" mechanism is interesting but speculative without enrollment data.
- **Data gotcha:** MCMV uses 6-digit IBGE codes, IDEB uses 7-digit (with check digit). Merge silently failed until the type mismatch was caught.
- **Review feedback adopted:** Toned down causal mechanism language, added contract-vs-delivery timing discussion, acknowledged aggregation as key limitation, fixed text-table inconsistency in pre-treatment means.
