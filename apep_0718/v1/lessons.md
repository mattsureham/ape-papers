## Discovery
- **Idea selected:** idea_1483 — Tornado path boundaries as spatial RDD for manufactured housing destruction
- **Data source:** NOAA SPC tornado database (70,022 records) + Census ACS API (tract-level) — both worked flawlessly
- **Key risk:** Census tracts too coarse for the spatial scale of tornado paths

## Execution
- **What worked:** Data pipeline executed cleanly — NOAA CSV, spatial polygon construction with `sf`, Census TIGER/Line boundaries, ACS API. 2,094 EF2+ tornado events, 6,360 analysis tracts across 34 states. The vacancy rate effect (1.76 pp, p=0.01) was robust across bandwidths.
- **What didn't:** The mobile home share RDD was imprecise (p=0.41). The fundamental mismatch between tract size (miles) and tornado path width (yards) creates severe measurement error. McCrary density test failed (p<0.01), likely due to tract geometry variation. The "replacement problem" mechanism remained suggestive but not causally identified.
- **Review feedback adopted:** Strengthened discussion of tract-level limitations, added explicit treatment of McCrary failure, reframed conclusions around vacancy persistence rather than replacement mechanism. Acknowledged need for parcel-level data in future work.

## Key Lesson
Spatial RDDs require the unit of analysis to be smaller than the treatment zone. Census tracts are too coarse for tornado path boundaries. The right approach for this question is park-level or parcel-level data (HUD MHC registry, ATTOM), which would allow the running variable to be measured at the scale of individual manufactured housing communities.
