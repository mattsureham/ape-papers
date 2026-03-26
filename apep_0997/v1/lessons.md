## Discovery
- **Idea selected:** idea_1488 — Romania's 2019 construction tax holiday. Chosen for its clean binary sectoral treatment, massive intensity (>12pp combined tax cut), and built-in within-economy cross-sector counterfactual.
- **Data source:** Eurostat (nama_10_a64_e for annual employment, lfsq_egan2 for quarterly LFS, lc_lci_r2_q for labor cost index). INS Tempo SSL connection failed but wasn't needed.
- **Key risk:** Few clusters (10 sectors, 1 treated). Addressed with leave-one-out, trend adjustment, and manufacturing-only control.

## Execution
- **What worked:** The self-employment share (total minus salaried employment) proved a powerful formalization proxy. The event study showed clean monotonic growth. Eurostat data was straightforward to fetch via the `eurostat` R package.
- **What didn't:** Wild cluster bootstrap failed due to package version issue. Could not get direct wage data from Eurostat for Romania. INS Tempo API had SSL issues.
- **Review feedback adopted:** Strengthened pre-trend discussion (acknowledged 2017 significant coefficient, noted it runs in opposite direction making results conservative). Expanded limitations section to address three concerns: few clusters, policy bundling, and COVID overlap. Added justification for self-employment share proxy.
