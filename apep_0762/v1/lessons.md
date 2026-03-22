## Discovery
- **Idea selected:** idea_1638 — Novel question (amenity value of darkness) filling a gap in hedonic environmental literature
- **Data source:** Zillow ZHVI zip-level monthly — free CSV download, excellent coverage, no API friction
- **Key risk:** Only 29 treated communities; few-cluster inference was the binding constraint

## Execution
- **What worked:** Zillow data download was seamless; CS-DiD estimation ran cleanly with 10 treatment cohorts; the "missing amenity premium" framing emerged naturally from the surprising negative result
- **What didn't:** VIIRS first stage was omitted (too complex for V1 scope); matching on only log(ZHVI) was flagged by all reviewers as too thin; RI p-value = 0.54 undermined statistical claims
- **Review feedback adopted:** Toned down all statistical language from "finds" to "suggests"; added explicit caveat about certification-vs-darkness decomposition; acknowledged t=-3 pre-trend; added limitations section
- **Key insight:** Environmental amenity capitalization is not automatic — when compliance costs are visible and per-property (unlike diffuse pollution), they can dominate amenity gains. The Flagstaff exception confirms this: pre-existing demand for darkness must be strong enough to outweigh costs.
