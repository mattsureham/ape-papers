## Discovery
- **Idea selected:** idea_0471 — PDUFA deadline bunching and post-market drug safety
- **Data source:** FDA NME compilation + openFDA FAERS API — API worked well after fixing URL encoding bug (`+AND+` → `" AND "` for httr2)
- **Key risk:** RD severely underpowered with only 11 observations below cutoff

## Execution
- **What worked:** Bunching analysis is clean and striking (63 drugs in [300,310) vs counterfactual 11). FAERS API linkage covered 312/538 drugs. The decomposition from raw to controlled estimates tells a compelling confounding story.
- **What didn't:** RD design fundamentally limited by asymmetric data — only 11 drugs below day 300 with FAERS data. Donut-RD failed due to matrix singularity. Priority review placebo returned 0 drugs because FAERS cache only contained standard-review drugs.
- **Review feedback adopted:** (1) Fixed false covariate smoothness claim — orphan and fast-track show significant discontinuities at cutoff, now honestly acknowledged. (2) Toned down causal language throughout — abstract, discussion, and conclusion now reflect that this is suggestive evidence, not definitive causality. (3) Reframed RD from "main design" to "supplementary diagnostic" given power limitations. (4) Added FAERS measurement limitations as explicit caveat.
- **Key lesson:** When the RD has severe power problems, be honest about what the design can deliver. A well-characterized null with transparent limitations is more credible than overclaimed causality.
