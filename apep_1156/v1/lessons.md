## Discovery
- **Idea selected:** idea_0108 — Mexico's AVGM gender violence alerts. Chosen after 4 overlap rejections; genuinely novel (no prior causal evaluation exists).
- **Data source:** SESNSP municipal crime incidence from GitHub mirror (lapanquecita/incidencia-delictiva). Free, comprehensive, monthly. Had to use the zip file (municipal.zip) for monthly columns — the timeseries CSV was annual only.
- **Key risk:** State-level clustering with only 32 units; reporting vs. violence channel decomposition depends on feminicide being a "hard" outcome.

## Execution
- **What worked:** The dual-outcome design (DV reports + feminicide) is the paper's strongest asset. CS-DiD shows DV up (+0.37), feminicide down (-0.92), property null — clean pattern. The "reporting dividend" mechanism generalizes well.
- **What didn't:** Feminicide magnitude is implausibly large (-1.10 SDE), partly driven by reclassification and sparse counts. State-level aggregation loses within-state variation. TWFE gives much smaller/insignificant DV effect (0.08), highlighting treatment heterogeneity but also raising questions about CS-DiD stability with 32 units.
- **Review feedback adopted:** Added total intentional homicide (homicidio doloso) as reclassification test — also declines (-0.21, p<0.001), ruling out pure reclassification. Acknowledged pre-trend concern at t=-12. Strengthened feminicide caveats. Reviewers flagged municipality-level analysis as priority for V2.
