## Discovery
- **Idea selected:** idea_0654 — Cross-hazard injury substitution from OSHA enforcement (adapted to silica standard since enforcement data was inaccessible)
- **Data source:** OSHA ITA Form 300A (2016-2024, 2.8M establishment-years) — clean download from osha.gov
- **Key risk:** OSHA enforcement/IMIS data no longer bulk-downloadable; had to pivot from establishment-level NEP treatment to industry-level regulatory treatment

## Execution
- **What worked:** ITA data is rich — 6 disaggregated hazard categories enable within-establishment hazard-type comparisons. The saturated triple-diff (estab×hazard + hazard×year + estab×year FEs) is clean.
- **What didn't:** (1) OSHA enforcement data portal (enforcedata.dol.gov) redirects to a JS SPA, breaking bulk download. (2) Only 3 pre-periods with 2019 cutoff forced pivot to 2022 engineering controls deadline. (3) COVID massively inflated respiratory reporting 2020-2022.
- **Review feedback adopted:** Decomposed DDD by hazard category (illness-only = null, driven by total injuries). Foregrounded COVID attenuation. Softened causal claims per GPT-5.4's incisive critique.

## Key finding
No cross-hazard substitution among illness categories (SDE = Null). Total injuries declined at high-silica firms (complementarity), but this is concentrated in COVID era and should be treated cautiously.
