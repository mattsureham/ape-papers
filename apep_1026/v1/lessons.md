## Discovery
- **Idea selected:** idea_0345 — marijuana legalization/FHA mortgage exclusion. Chosen for the sharp institutional mechanism (HUD Handbook 4000.1 cannabis exclusion), built-in counterfactual (FHA vs conventional), and massive HMDA data.
- **Data source:** CFPB Data Browser API — works well per-state per-year, but national queries without state filter return 400. Per-state queries are reliable (~2-5 sec each, 306 total).
- **Key risk:** Scale mismatch between cannabis workforce (0.3% of employment) and state-level mortgage aggregates.

## Execution
- **What worked:** CFPB API is excellent and free. HMDA data at loan level with full loan type detail. Pre-trends pristine (p=0.86). VA placebo dead null. The institutional story writes itself.
- **What didn't:** The effect is undetectable at state-year level. Back-of-envelope shows MDE ≈ 5× the plausible maximum effect. County-level with QCEW cannabis employment would be the right design.
- **TWFE-CS divergence:** The biggest finding. TWFE shows significant -1.0 pp; CS shows null -0.1 pp. Illinois (2019 cohort) drives the divergence with a positive 1.16 pp group ATT. This became the paper's central contribution.
- **Review feedback adopted:** Fixed Table 1 income bug (double-dividing by 1000). Added explicit power calculation. Rebalanced framing toward economic null over methodology lesson. Acknowledged ITT design.
