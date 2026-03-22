## Discovery
- **Idea selected:** idea_1657 — Spatial RDD at state borders for cellphone bans, chosen for 10 border pairs (internal replication), vivid outcome (traffic fatalities), and built-in placebo (non-phone distractions)
- **Data source:** NHTSA FARS 2015-2022 — column names changed across years (MDRDSTRD→DRDISTRACT in 2020+, DRUNK_DR dropped in 2021+), requiring schema-aware parsing
- **Key risk:** Phone distraction coding in FARS is sparse and inconsistent across states; pre-existing reporting differences between treated/control states complicate phone-specific mechanism tests

## Execution
- **What worked:** FARS data download straightforward (8 ZIP files, ~240MB). Geocoded crash coordinates enabled precise distance-to-border computation. The stacked diff-in-disc design across 8 pairs provided natural internal replication.
- **What didn't:** Lost 2 of 10 border pairs (IN-OH, MN-ND) due to TIGER shapefile boundary detection failures — st_intersection of boundaries returned empty for these pairs. Phone-distraction rates differ 2x between treated/control sides pre-treatment, making phone-specific outcomes unreliable for mechanism tests.
- **Review feedback adopted:** Added MDE discussion, softened "enforcement mirage" language, better discussed pre-treatment phone-distraction discontinuity, acknowledged county-level aggregation limitation. Reviewers unanimously suggested crash-level analysis with continuous signed distance — excellent V2 direction.
