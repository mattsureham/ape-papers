## Discovery
- **Idea selected:** idea_0581 — Spatial RDD at US wilderness boundaries, chosen for sharp identification and massive sample
- **Data source:** WDPA (boundaries), Hansen GFC v1.11 (tree cover loss), elevatr/SRTM (elevation) — WDPA required nested unzipping; wilderness.net endpoint was down
- **Key risk:** Fire confound — Hansen data conflates harvest with fire, which is the dominant cause of tree cover loss in PNW

## Execution
- **What worked:** The spatial RDD setup is clean and visually compelling. 500K pixel sample with 359 wilderness boundaries provides ample power. rdrobust estimation with bias-corrected inference is the correct framework.
- **What didn't:** Baseline tree cover balance failed (1.5 pp discontinuity, p < 0.01) and density test rejected (p = 0.002). The fire confound limits the claim from "fortress prevents harvest" to "fortress reduces total tree cover loss, which may include harvest and fire differences."
- **Review feedback adopted:** Toned down conclusion language, added overlapping-regulation explanation for modest effect size, explicitly acknowledged scope limitation to PNW
