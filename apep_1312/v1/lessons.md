## Discovery
- **Idea selected:** idea_1160 — North Macedonia's 12-month progressive tax experiment with symmetric on-off shock
- **Data source:** Statistics North Macedonia PXWeb API — monthly sector-level wages, no authentication needed
- **Key risk:** Only 19 sectors → underpowered for detecting plausible effect sizes

## Execution
- **What worked:** Data fetch was clean (4,807 obs from public API). Continuous-treatment DiD with wild cluster bootstrap and permutation inference — appropriate for few-cluster setting. Honest null result with transparent power limitations.
- **What didn't:** The "visible" raw data patterns (16.5% ICT drop) turned out to be December bonus effects absorbed by month FE. Sector-level aggregation washes out individual-level tax responses. The post-2020 period is contaminated by COVID.
- **Review feedback adopted:** Added raw-vs-DiD reconciliation paragraph. Expanded threats section with exposure measurement error and COVID caveats. Added formal MDE calculation. Acknowledged December bonus seasonality.
- **Key lesson:** Sector-level studies of tax reforms affecting <1% of taxpayers are inherently underpowered. The clean identification (on-off structure) couldn't compensate for thin cross-sectional variation. Individual-level administrative data are necessary for this class of question.
