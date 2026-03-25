## Discovery
- **Idea selected:** idea_0343 — Nursing home staffing mandates using CMS PBJ-era data
- **Data source:** CMS Provider Data Catalog (Health Deficiencies, Provider Info, Penalties, Quality Measures) — PBJ daily staffing API only serves current quarter, requiring pivot to deficiency-based panel
- **Key risk:** Historical PBJ data unavailability forced abandonment of employee/contractor decomposition

## Execution
- **What worked:** The Health Deficiency database (419K records, 2017-2026) provided a rich facility-survey panel. The "detection dividend" finding — mandates increase total deficiency citations while reducing infection control deficiencies — is genuinely novel and names an economic object.
- **What didn't:** The cross-sectional first stage (current HPRD on mandate status) is weak because the PBJ API only serves the current quarter. A panel first stage would dramatically strengthen the paper. The Callaway-Sant'Anna estimator returned degenerate results (0/NA) on the unbalanced panel — Sun-Abraham via fixest worked better.
- **Review feedback adopted:** Softened detection dividend framing to match evidence strength; added caveat about few-cluster inference (6 treated states); acknowledged cross-sectional first-stage limitation explicitly; replaced CS-DiD row in robustness table with Sun-Abraham average post-treatment coefficient.
