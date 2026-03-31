## Discovery
- **Idea selected:** idea_2047 — FEMA concurrent disaster load as IV for bureaucratic capacity. Picked for first-order stakes (climate adaptation), novel IV (no published paper uses this), and massive free data (OpenFEMA REST API).
- **Data source:** OpenFEMA — 69,769 declaration rows, 152,264 IHP records, 273,979 PA projects. API has a hard 100K pagination limit requiring batched queries by state/year.
- **Key risk:** COVID-era declarations (2020-2023) create massive leverage in the instrument; need to show results aren't just COVID artifacts.

## Execution
- **What worked:** The heterogeneity split (hurricane vs. non-hurricane) was the breakthrough — pooled estimates were imprecise and misleading, but decomposition revealed the "selective dilution" mechanism where capacity constraints bind only for labor-intensive disaster types.
- **What didn't:** The inspection-rate mechanism test is imprecise (beta = -0.036, SE = 0.044), likely because the variable aggregates too coarsely. PA obligation lag shows no significant relationship, suggesting the speed of infrastructure reimbursement is less affected than household-level approval decisions.
- **Review feedback adopted:** Strengthened caveats about COVID confounding, addressed registration endogeneity (denominator effect works against our finding, making estimate conservative), fixed overclaim language ("no effect" → "near-zero effects"), added compositional explanation for positive pooled estimate.
