## Discovery
- **Idea selected:** idea_1190 — Prevailing wage repeals and racial earnings gap, chosen for QWI microdata (tournament winner), first-order stakes, and sharp institutional lever
- **Data source:** QWI rh/n3 from Azure — needed to filter to `geo_level == "S"` and `agg_level == 1573` for clean state-level aggregates
- **Key risk:** Only 6 treated states creates few-cluster inference challenge

## Execution
- **What worked:** Wild cluster bootstrap confirmed TWFE significance (p=0.015). Leave-one-out showed no single state drives the result. Manufacturing placebo showed null.
- **What didn't:** The TWFE-CS discrepancy undermines clean causal claims. CS gives -0.007 (insignificant) vs TWFE -0.032 (significant). The mechanism test showed uniform effects across subsectors, killing the clean "public vs private" identification that was the idea's centerpiece.
- **Review feedback adopted:** Softened all causal language, added compositional concerns, acknowledged RTW confound explicitly, tempered conclusion to "suggests but does not definitively establish"
- **Key lesson for future:** With only 6 treated units in a staggered design, always lead with CS (not TWFE) as the primary specification, and frame TWFE as a comparison. The county-level data (which the manifest suggested) would have been much stronger.
