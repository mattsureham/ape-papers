## Discovery
- **Idea selected:** idea_0485 — ZFE low-emission zones and populist voting in France; timely given France's 2025 policy reversal
- **Data source:** BNZFE (transport.data.gouv.fr) + data.gouv.fr election files + geo.api.gouv.fr commune centroids — all public, no API keys needed
- **Key risk:** Small N of treated communes (50) inherent to ZFE geography; commune-level centroid classification creates measurement error

## Execution
- **What worked:** The methodological finding (spurious +17.6pp without metro FE vs null with FE) makes a strong pedagogical point. Placebo tests clean with metro FE. McCrary density test passes (p=0.51). The null result is policy-relevant.
- **What didn't:** 2017 election data in XLS format with unnamed columns required manual column mapping. 2022 data in semicolon-separated TXT with 103 columns needed careful candidate identification by position. geo.api.gouv.fr bulk query failed — had to fetch per-département. `fwildclusterboot` R package unavailable for current R version.
- **Review feedback adopted:** Strengthened power analysis framing ("no evidence of large localized effects" rather than "no backlash"). Added discussion of temporal heterogeneity across metros (Grenoble 3yr exposure vs Toulouse months). Clarified estimand as boundary effect vs diffuse national backlash. Acknowledged centroid measurement error as attenuation risk more prominently.
- **Review feedback deferred to V2:** DVF housing transaction sorting test, area-weighted treatment exposure, event-study by exposure duration, wild cluster bootstrap inference, enforcement heterogeneity measurement.
