## Discovery
- **Idea selected:** idea_0952 — VRU funding and crime displacement. Chose for vivid object (displacement vs deterrence), first-order outcome (knife crime), and clean treatment-control boundary.
- **Data source:** ONS Police Force Area Data Tables (annual knife crime by PFA). Pivoted from police.uk bulk archives (1.68GB/month, impractical) to ONS single-file download (659KB).
- **Key risk:** Selection on pre-treatment violence would confound direct effect; extreme geographic coverage would leave few interior comparators.

## Execution
- **What worked:** The spillover decomposition framework (boundary vs interior forces) is a genuine methodological contribution. The data pipeline was simple and clean once I found the ONS tables. The paper's honesty about pre-trends and RI fragility is a strength.
- **What didn't:** The single interior force (Dyfed-Powys) means the spillover estimate is effectively a 21-vs-1 comparison. This structural limitation was foreseeable from the idea manifest but only became concrete during analysis. Annual data prevents monthly event studies.
- **Review feedback adopted:** Added footnote justifying annual data choice over monthly police.uk archives. Strengthened caveats on spillover interpretation, noting the single-comparator fragility. Added suggestion for future work using LSOA-level distance gradients.
