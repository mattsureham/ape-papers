## Discovery
- **Idea selected:** idea_0968 — Cross-system fiscal spillovers from Swiss DI reforms on health costs
- **Data source:** BAG OKP Dashboard (health costs by canton, 1997-2024) + BFS PXWeb (IV integration measures, pension recipients)
- **Key risk:** Treatment variable captures disability burden, not reform intensity — no credible first stage

## Execution
- **What worked:** Data fetching from BAG/BFS was smooth; cost decomposition by service type (pharmacy/physio/home care) provides compelling descriptive evidence; event study pre-trends are clean
- **What didn't:** First stage is essentially zero (DI rate does not predict integration intensity); main result sensitive to canton-specific trends; log specification returns null
- **Review feedback adopted:** Moderated causal claims; expanded threats-to-identification section; acknowledged treatment definition weakness; noted need for wild cluster bootstrap

## Key takeaway for V2
Use actual canton-level integration intensity (BFS PXWeb data already fetched) as treatment variable with 2SLS/Bartik design rather than pre-reform DI rate as dose.
