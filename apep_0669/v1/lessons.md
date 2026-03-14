## Discovery
- **Idea selected:** idea_0583 — Spatial RDD at MO-IL border after Dobbs, testing Tiebout capitalization of reproductive rights
- **Data source:** Zillow ZHVI (ZIP-level, monthly) + Census TIGER shapefiles — both downloaded cleanly, no API issues
- **Key risk:** Pre-existing differential appreciation between MO and IL states could confound the border design

## Execution
- **What worked:** The diff-in-disc framework cleanly separates border effects from spatial trends. The bandwidth sensitivity analysis (Table 3) is the most telling result — the coefficient flips sign from negative at 10km to positive at wider bandwidths, revealing that the "positive effect" is entirely driven by MO interior appreciation, not a border discontinuity.
- **What didn't:** The event study pre-trends are non-trivially violated — MO was appreciating faster than IL before Dobbs. This is inherent to the metro and not fixable by the design.
- **Review feedback adopted:** (1) Re-anchored preferred specification on the 15km narrow-bandwidth estimate rather than the full-sample linear-distance model; (2) Tempered null claims — "no detectable effect" rather than "precisely estimated null"; (3) Added caveat on KC referendum timing (August vs June); (4) Added discussion of ZHVI smoothing and its implications for power; (5) Added economic calibration benchmarks from capitalization literature (5-10% for daily-use amenities).

## Key insight
The null is genuine but the paper's strength lies in the *pattern* across bandwidths and borders, not any single coefficient. Future border-design papers should present bandwidth sensitivity as the main exhibit, not a robustness check.
