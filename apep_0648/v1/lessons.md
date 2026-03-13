## Discovery
- **Idea selected:** idea_0064 — PBM spread pricing bans and community pharmacy survival. First causal evidence on a hot legislative topic with zero prior studies.
- **Data source:** Census CBP (NAICS 446110) + ACS population — reliable but coarse (state-year). SDUD (Medicaid drug spending) returned 404 for all years, dropped as secondary outcome.
- **Key risk:** Only 12 treated states; state-level analysis limits power. Null result was always the most likely outcome given structural forces driving pharmacy consolidation.

## Execution
- **What worked:** Combined analysis pipeline (run_all.R) avoided persistent linter overwriting of individual R scripts. Inlining tables and bibliography in paper.tex prevented the same corruption.
- **What didn't:** External linter repeatedly overwrote R scripts and table files with old constitutional carry (apep_0636 predecessor) content. Cost ~30 minutes debugging. Census PEP API broken for post-2020 data; switching to ACS 1-year estimates worked but required 2020 interpolation.
- **Key insight:** For V1 null-result papers, the framing matters enormously. "The Phantom Fix" framing — policy addresses a symptom, not the disease — is more compelling than "we found no effect."
