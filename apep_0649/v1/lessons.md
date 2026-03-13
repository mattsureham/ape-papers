## Discovery
- **Idea selected:** idea_0571 — UK Clean Air Zones property value capitalization via spatial diff-in-disc
- **Data source:** HM Land Registry Price Paid + postcodes.io geocoding — both reliable, no API issues
- **Key risk:** OSM Overpass API failed for all 7 CAZ boundaries (504/429 errors), forcing circular approximations. This became the paper's main weakness alongside the pre-trend concern.

## Execution
- **What worked:** Large sample (50K transactions within 500m), charge class heterogeneity (B/C/D) as key finding, clean spatial RDD pipeline in R
- **What didn't:** OSM boundary data completely unavailable; pre-period placebo shows significant negative coefficient (-5.7%) undermining parallel trends assumption; all reviewers flagged both issues
- **Review feedback adopted:** Softened abstract claims, removed "striking asymmetry" framing, rewrote pre-trend discussion to honestly acknowledge identification concern, replaced "Goldilocks" policy language with "suggestive evidence"
- **Lessons for future:** (1) Always have backup boundary data sources beyond OSM. (2) Pre-trends that go the wrong way need honest treatment, not creative reinterpretation. (3) Charge class heterogeneity was the paper's strongest contribution — lean into dose-response designs.
