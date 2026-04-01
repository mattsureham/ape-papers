## Discovery
- **Idea selected:** idea_0944 — Swiss regulatory thresholds with 2020 GEA shock at 100 employees
- **Data source:** BFS STATENT (PXWeb API, no key needed) — excellent coverage (2011-2023, all workplaces), but only 4 coarse size bins
- **Key risk:** Coarse bins prevent direct bunching estimation at 100-employee threshold

## Execution
- **What worked:** BFS PXWeb API is reliable and well-structured. The within-bin moment approach (testing whether avg firm size shifted) is a genuine methodological contribution for settings where only aggregate bin data is available.
- **What didn't:** Tried OECD SDBS, Eurostat SBS, BFS R package for finer bins — none available for Switzerland at the 50-99/100-249 granularity. The identification strategy is fundamentally limited by data coarseness.
- **Review feedback adopted:** Strengthened attenuation/power discussion with explicit calibration of minimum detectable effects. Reframed null as upper bound rather than definitive zero. Highlighted 2015-2023 window as preferred specification.
- **Key lesson:** When data binning masks the treatment threshold, pivot from level to moment-based tests (averages, ratios, gender composition), but be transparent that this creates attenuation. Reviewers correctly noted the power limitation — future work should seek restricted BFS microdata.
