## Discovery
- **Idea selected:** idea_0746 — USPS mail slowdown and preventable hospitalizations. Chosen for the memorable hook ("mail as health infrastructure"), clean distance-based treatment, and built-in pharmacy desert placebo.
- **Data source:** County Health Rankings (countyhealthrankings.org) — annual preventable hospitalization rates. Older years (2015-2018) use different URL patterns and column names from newer years (2019+).
- **Key risk:** Treatment proxy (metro distance) vs actual P&DC-based service standards introduces measurement error.

## Execution
- **What worked:** CHR data is reliable and freely available across 10 years. Census CBP pharmacy counts provide a clean pharmacy desert measure. The 3,074-county panel with county/year FE gives a well-powered design.
- **What didn't:** The short panel (2019-2024) produced a suggestive delayed effect in pharmacy deserts that evaporated with the extended panel (2015-2024) — the "finding" was a pre-trend artifact. This is an important lesson: always check whether your result survives a longer baseline before getting attached to it.
- **Review feedback adopted:** Added power calculation, discussed measurement error/attenuation bias explicitly, clarified triple-diff specification (Slowdown×Desert absorbed by FE), addressed 2021 partial treatment, improved placebo outcome description.

## Key Takeaways
- **Panel length can change the story.** A clean 3-year pre-period gave "clean" pre-trends and a suggestive finding. A 7-year pre-period exposed differential long-run dynamics that invalidated the short-panel result.
- **Well-powered nulls are publishable** but require explicit power calculations and honest discussion of measurement limitations.
- **County-level annual data may be too aggregated** to detect effects operating at the individual-patient level. The 10:1 dilution problem (10% mail-order users in a county) is real.
