## Discovery
- **Idea selected:** idea_0635 — Familias en Acción at 20: municipality-level effects of Colombia's CCT
- **Data source:** ColOpenData (DANE 2018 Census) + datos.gov.co (FeA beneficiaries) — both API-accessible, rich municipality-level data
- **Key risk:** Reconstructing the original 50/50 matched municipality list from published papers — proved infeasible, required design pivot

## Execution
- **What worked:** ColOpenData delivered rich census data quickly (9 datasets, 800K+ rows). The cohort-exposure design (Duflo 2001 style) was a natural fit once the matched design fell through. The datos.gov.co Socrata API for FeA beneficiaries (3.96M records) worked via aggregation queries. The value-added specification (conditioning on old-cohort literacy) produced the paper's strongest finding.
- **What didn't:** datos.gov.co population projections and NBI historical data returned empty responses at all tried resource IDs. ColOpenData's `download_pop_projections()` function has a bug (`x must be a list, not a list matrix`). The FeA beneficiary data only covers 2012+ ("Más Familias" rebranding), creating a timing mismatch with the 2002 program launch.
- **Review feedback adopted:** Softened all causal claims to "associations consistent with program effectiveness." Expanded threats-to-validity from one paragraph to four explicit subsections covering endogeneity, ceiling effects, timing mismatch, and lack of pre-trends. Added discussion of the value-added interpretation and mechanical convergence concern.
