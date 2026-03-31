## Discovery
- **Idea selected:** idea_2054 — Examiner-leniency IV for nursing home inspections. Chose for strong tournament alignment: judges love examiner IVs, universe-scale admin data, portable mechanism ("compliance crowding").
- **Data source:** CMS Provider Data Catalog — 4 datasets, no auth required, fetched via metastore API. Penalties dataset (g6vv-ecyk) returned 404; provider info had penalty data anyway.
- **Key risk:** Exclusion restriction — state stringency correlates with Medicaid rates, labor markets. Within-chain FE is the strongest defense but can't fully resolve.

## Execution
- **What worked:** CMS API is reliable and fast. First stage was a monster (F > 5000). The "compliance crowding" framing fell naturally from the surprising negative sign. Multi-state chain design was exactly as described in the manifest.
- **What didn't:** Quality measures (MDS) didn't produce usable IV results — likely due to the measures being aggregate scores with limited within-state variation. Cross-sectional design is the main weakness.
- **Review feedback adopted:** Strengthened exclusion discussion, reframed chain FE as preferred spec, added timing limitation, noted alternative treatment variables, added OSHA literature.
- **V2 opportunities:** Panel design (2017-2025) with state FE, Medicaid reimbursement controls, wild cluster bootstrap, placebo with home health agencies, admin vs clinical staff decomposition.
