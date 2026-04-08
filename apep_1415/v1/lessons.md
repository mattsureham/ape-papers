## Discovery
- **Idea selected:** idea_1611 — Morocco cannabis legalization, zero existing causal papers, sharp geographic boundary
- **Data source:** NASA Black Marble VNP46A4 (nightlights) + HDX admin boundaries — BlackMarble HDF5 required manual georeference (MODIS sinusoidal tile extent/CRS not embedded in subdatasets)
- **Key risk:** Nightlights may be too coarse to detect agricultural formalization effects in rural mountains

## Execution
- **What worked:** Grid-cell approach (5km × 5km) compensated for lack of commune boundaries; 1,274 cells gave adequate power; pre-trends were clean across all specifications
- **What didn't:** VIIRS EOG cloud-optimized GeoTIFFs failed via vsicurl (files too large / timeout); ACLED API auth format different from expected; FAOSTAT API returned 521; commune boundaries not available from HDX (only admin2)
- **Review feedback adopted:** External review APIs failed (OpenRouter auth issue) — no reviewer feedback incorporated
- **Key finding:** Legalization discount mechanism — formalization strips risk premium, producing muted aggregate effects. Border sample shows significant localized effect (0.087, p=0.02)
