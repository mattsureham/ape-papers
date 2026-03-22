## Discovery
- **Idea selected:** idea_0699 — Swiss franc shock and tourism demand. Pivoted from idea_0695 (bunching) after discovering STATENT has only 4 coarse firm-size bins.
- **Data source:** BFS HESTA via PXWeb API — excellent coverage (26 cantons × 77 origins × 12 months × 22 years). Exchange rates from FRED.
- **Key risk:** Pre-existing decline in Eurozone tourism relative to Swiss domestic (2010-2011 appreciation predated the floor).

## Execution
- **What worked:** The within-canton, across-nationality DiD produced a large, significant main result. The heterogeneity by canton type (tourism vs. urban) is a compelling finding. PXWeb API data fetch was reliable once the JSON format was figured out.
- **What didn't:** The Bartik specification was underpowered due to limited cross-canton variation in Eurozone shares. Pre-trends in the event study undermined the causal interpretation. The binary Eurozone/non-Eurozone treatment wasted the granular origin-level variation.
- **Review feedback adopted:** Toned down causal language, fixed text-table inconsistencies in event study discussion, reframed Bartik as uninformative, added honest pre-trend discussion.

## Key Lesson
**For exchange rate natural experiments:** The within-market design (same hotel, different visitor nationality) is conceptually clean, but Swiss domestic tourism is not an ideal control for foreign tourism due to secular compositional shifts. Future versions should use continuous exchange rate exposure at the origin level and restrict the comparison to European origins only. The PXWeb API `format = "json"` is the reliable choice — avoid `json-stat2` and `csv` formats which have parsing issues.
