## Discovery
- **Idea selected:** idea_0579 — France REP school boundary spatial RDD. Chose for vivid paradox (stigma vs. resources), massive DVF data, sharp spatial identification following Black (1999, AER).
- **Data source:** DVF geolocalized (data.gouv.fr), college sector GeoJSON, REP college list from data.education.gouv.fr
- **Key risk:** Catchment boundaries not fully arbitrary — may track socioeconomic gradients

## Execution
- **What worked:** The batched spatial processing pipeline (st_touches → boundary extraction → caching → batched st_nearest_feature) scaled to 43K polygons and 5.3M transactions. The 8,117 boundary segments provide massive internal replication.
- **What didn't:** Naive st_union of 43K polygons OOM-killed; URL for GeoJSON was wrong on first attempt (data.education.gouv.fr export vs static.data.gouv.fr). REP status field uses legacy codes (ECLAIR, RRS) requiring remapping.
- **Review feedback adopted:** [to be updated after reviews complete]
