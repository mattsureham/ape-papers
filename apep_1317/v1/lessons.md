## Discovery
- **Idea selected:** idea_0612 — Colombia's draft lottery during active armed conflict, completely unexploited in the literature
- **Data source:** ICFES Saber 11 and Saber Pro via datos.gov.co Socrata API — pivoted from GEIH labor data (API inaccessible) and World Bank (502 error)
- **Key risk:** DDD identification weaker than lottery-based IV; multiple confounds from peace deal

## Execution
- **What worked:** datos.gov.co provided 1M+ Saber 11 records and 100K Saber Pro records with exact birth dates, enabling precise cohort identification. The DDD produced clean, significant results with a correctly null female placebo.
- **What didn't:** World Bank API was down (502), ACLED DNS unresolvable, DANE direct downloads require authentication. Lost ~30 min debugging API failures before pivoting to datos.gov.co Socrata.
- **Review feedback adopted:** Added acknowledgment of lottery departure, tempered causal claims, discussed peace deal confounds, noted bachiller distinction, reframed as composite draft environment effect rather than single anticipatory channel.
