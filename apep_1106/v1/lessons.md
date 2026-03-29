## Discovery
- **Idea selected:** idea_1955 — GBIF citizen science data + EU neonicotinoid derogations. Selected for novel data source, clean staggered natural experiment, and first-order environmental stakes.
- **Data source:** GBIF API (bee/beetle/insect counts), Eurostat (sugar beet area), hand-compiled derogation timeline. GBIF API straightforward; Eurostat required direct JSON-stat parsing (the R package failed on the crop code).
- **Key risk:** Observation effort bias in citizen science data. Mitigated by share normalization and effort controls, but country-level aggregation proved too coarse.

## Execution
- **What worked:** The staggered DiD design is clean — 11 treated countries, 16 controls, 6 pre-periods, parallel trends validated. The beetle placebo performs well. HonestDiD and leave-one-out provide thorough robustness.
- **What didn't:** Country-year level aggregation is too coarse to detect effects of a crop-specific seed treatment. All three reviewers flagged this as the main weakness. The idea manifest promised NUTS-2 level analysis, which would have been much stronger.
- **Review feedback adopted:** Added power calculation/MDE, effort orthogonality test, removed overclaiming language ("precisely estimated null"), added explicit country-level limitation paragraph, fixed data description inconsistencies.
- **Key lesson:** For citizen science biodiversity data, subnational analysis is essential. Country-year panels dilute localized effects. A V2 should construct NUTS-2 × year panels using geolocated GBIF records.
