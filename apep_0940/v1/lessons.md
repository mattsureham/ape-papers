## Discovery
- **Idea selected:** idea_1569 — Denmark's parallel society housing designation list
- **Data source:** DST StatBank API (FOLK1E, RAS200) — excellent public API, quarterly population by ancestry and municipality
- **Key risk:** Municipality-level aggregation dilutes estate-level effects; only 15 treated municipalities

## Execution
- **What worked:** DST StatBank API is reliable and well-structured; designation list was compilable from public sources (CPH Post, The Local DK, Wikipedia cross-references); clean null result with strong diagnostics (RI, pre-trends, LOO, placebo)
- **What didn't:** Could not find machine-readable designation list from government (PDFs only); FLYT47 mobility table referenced in idea manifest doesn't exist; log NW population had failed pre-trends (convergence artifact)
- **Review feedback adopted:** Added quantitative dilution calculation in Discussion; tempered claims in Introduction and Conclusion to match municipality-level unit of analysis; reframed contribution as boundary condition rather than definitive null
