## Discovery
- **Idea selected:** idea_2341 — Medicare ASP lag windfall. Clean institutional mechanism with formula-based identification.
- **Data source:** CMS ASP Quarterly Pricing Files (26 quarters, 2017Q3-2024Q4) + FDA Orange Book + Part B Spending Dashboard
- **Key risk:** Event definition from outcome variable creates circularity concern (mitigated by placebo test)

## Execution
- **What worked:** The ASP pricing files are highly structured — clean drug-quarter panel with minimal missingness. Placebo test (474 no-entry drugs) was perfectly flat, providing strong falsification. The $169M/year aggregate cost estimate gives policy bite.
- **What didn't:** CMS data URLs change frequently between old/new patterns. NDC-HCPCS crosswalk was 404. Orange Book has messy tilde-delimited format. Quarterly Part B spending only covers 2024-2025 (not useful for panel).
- **Review feedback adopted:** Reframed title from "Subsidizes Brand Drugs" to "Delayed Pass-Through" per GPT-5.4 reviewer. Toned down behavioral claims throughout — paper now clearly states it measures mechanical overpayment, not physician response. Fixed normalization window to exclude lag window (was -4 to -1, now -6 to -3). Quarter FEs caused multicollinearity — reverted to drug FEs only.
