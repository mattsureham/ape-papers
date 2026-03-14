## Discovery
- **Idea selected:** idea_0891 — UK office-to-residential PD rights, Bartik design with 242+ treated LAs
- **Data source:** MHCLG Table 122/123 (housing supply), VOA floorspace (treatment), UK HPI (prices), NOMIS (population)
- **Key risk:** Bartik exposure (office share) correlates with economic dynamism, confounding demand and supply channels

## Execution
- **What worked:** Table 122 provided 19 years of net additions data (2006-2024), giving 7 pre-periods. VOA floorspace by LA cleanly separates office-heavy from non-office areas. UK HPI by property type enables flat vs. house price decomposition.
- **What didn't:** Table 123 ODS had inconsistent formatting across years (header position, column names with embedded newlines). HPI date format was DD/MM/YYYY not ISO. Original panel used only Table 123 starting from 2012, giving just 1 pre-period — had to discover and integrate Table 122 for extended time series.
- **Review feedback adopted:** Rescaled price coefficient interpretation (per-SD, not per-unit), added Class MA explanation for 2022 event study reversal, clarified pre-trends evidence with 7 pre-periods. All three reviewers flagged VOA 2025 vs 2012 measurement issue — acknowledged as limitation.
