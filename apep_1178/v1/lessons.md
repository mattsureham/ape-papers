## Discovery
- **Idea selected:** idea_1792 — CRNA supervision opt-out, chosen for strong quasi-experimental variation (22 treated states, staggered), first labor-market study of this policy, and data accessibility via Azure QWI
- **Data source:** Census QWI on Azure Blob Storage — fetched 15.2M rows of county×quarter×education×industry data, aggregated to state-year
- **Key risk:** BA+ education group captures more than CRNAs (also NPs, PAs); addressed as a limitation

## Execution
- **What worked:** Azure data pipeline worked smoothly; staggered DiD with C-S and Sun-Abraham implemented cleanly; placebos (education and industry) provide strong null confirmation
- **What didn't:** Azure connection string was truncated by shell semicolons (needed R-side fix); coefficient extraction from fixest required using index [1] instead of named lookup due to "TRUE" suffix on logical variables
- **Review feedback adopted:** Added MDE power calculation, softened mechanism claims, expanded composition limitations discussion, highlighted suggestive earnings result
- **Key finding:** Precisely estimated null on employment — the CMS supervision requirement was non-binding. Named mechanism: "supervision illusion"
