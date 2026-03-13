## Discovery
- **Idea selected:** idea_0584 — Border-county-pair DiD for paid family leave using QWI
- **Data source:** Census QWI via Azure Blob Storage (fast, reliable); Census county adjacency file (correct URL: `county_adjacency.txt`, not year-suffixed)
- **Key risk:** Few clusters (7 states) would undermine inference — confirmed as binding

## Execution
- **What worked:** QWI from Azure was clean and complete. Border-pair construction via adjacency file was straightforward. The cross-gender placebo was the paper's strongest contribution — it turned a null into a diagnostic.
- **What didn't:** Wild cluster bootstrap failed computationally with 7 clusters. Pre-trend F-test produced nonsensical values (64.7M) from non-PSD VCOV matrix. Wave-specific estimates were implausibly large due to macro confounders (Great Recession for NJ, COVID for WA).
- **Key lesson:** Border-county-pair designs need many more policy events than PFL provides. With 3 waves and 7 states, the design is fundamentally underpowered. The framing as a methodological cautionary note (not a causal paper) was the right call.
- **Review feedback adopted:** Fixed the F-test display (replaced with "unreliable" note), added macro context for wave-specific estimates, acknowledged government-sector placebo as stronger alternative, added caveats about male placebo interpretation.
