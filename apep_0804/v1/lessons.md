## Discovery
- **Idea selected:** idea_1706 — Autism insurance mandates and maternal labor supply. Chosen for: 46-state staggered adoption, ACS PUMS data, triple-diff with within-state placebo, novel contribution at intersection of two literatures.
- **Data source:** Census ACS PUMS FTP (2008-2019). Lesson: the Census API via tidycensus is extremely slow for national microdata; always use FTP CSVs for PUMS.
- **Key risk:** DREM is a broad proxy for ASD. Dilution attenuates estimates but the CI still rules out policy-relevant effects.

## Execution
- **What worked:** FTP download approach (~6 min for 12 years vs hours via API). The data.table + fixest pipeline handled 2.4M observations smoothly. The triple-diff design with state×DREM, year×DREM, and state×year FE is clean.
- **What didn't:** Initial tidycensus approach was too slow. Also discovered RELP variable name changes across years (REL in 2008-2009, RELP in 2010-2018, RELSHIPP in 2019).
- **Result:** Precisely estimated null across all outcomes and subgroups. Employment DDD = 0.13pp (SE=0.47pp). Event study flat pre and post.
- **Review feedback adopted:** (1) Added DREM-to-ASD dilution calibration with back-of-envelope scaling — even under extreme assumptions (30% ASD share), implied effect is 0.4pp, still negligible. (2) Added explicit ERISA preemption discussion and TOT scaling. (3) Toned down DPHY placebo interpretation (acknowledged it's imprecise, not "clean"). (4) Moderated Discussion and Conclusion — now acknowledges limited policy reach as alternative to time-complementarity explanation. (5) Added mandate generosity limitation note. Key reviewer concerns NOT addressed (would require new data/code): mandate generosity heterogeneity, insurance status stratification, wild-cluster bootstrap, fathers' employment placebo.
