## Discovery
- **Idea selected:** idea_0478 — French maternity ward closures and populist voting. Selected over cannabis border employment (already covered by apep_0183), sports betting/binge drinking (many APEP papers), and Czech co-payments (N=1). The state-abandonment hypothesis is timely and differentiated from carbon tax → populism (apep_0464).
- **Data source:** DREES SAE (2013-2024), data.gouv.fr elections (Parquet), INSEE commune centroids
- **Key risk:** DREES data only covers 2013+, limiting pre-period to pre-2013 elections using a frozen 2013 maternity landscape

## Execution
- **What worked:** data.gouv.fr election Parquet files are excellent — 27M records, clean id_election format, easy to filter. Commune coordinate data from data.gouv.fr is comprehensive. The CS-DiD estimator (`did` package) ran cleanly.
- **What didn't:** Pre-trends reject at p=0.0003, fundamentally limiting the causal interpretation. The 300-delivery regulatory threshold RD was not implemented (left for V2). Text-table inconsistencies after adding European elections were caught by reviewers — must always update prose after re-running analysis.
- **Review feedback adopted:** Fixed text-table inconsistencies (critical), softened causal language to acknowledge design limitations, clarified closure count discrepancy (536 facilities vs ~200 actual closures).
