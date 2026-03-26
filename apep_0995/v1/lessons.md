## Discovery
- **Idea selected:** idea_0486 — Loi NOTRe forced EPCI mergers → far-right voting. Chosen for massive treatment group (17k communes), clean identification, and portable mechanism.
- **Data source:** DGCL composition tables (data.cquest.org archive), election results (data.gouv.fr). API discovery was harder than expected — data.gouv.fr search doesn't index BANATIC well.
- **Key risk:** Only 2 pre-treatment elections (presidential) limits event study resolution.

## Execution
- **What worked:** Clean pre-trends confirmed the design. The DGCL files had exact SIREN-coded EPCI mapping pre/post reform. Massive sample gave precise null estimates.
- **What didn't:** geo.api.gouv.fr's "date" parameter doesn't return historical EPCI assignments — needed the CQuest archive instead. Wild cluster bootstrap hit memory limits.
- **Review feedback adopted:** Clarified treatment definition for absorbing EPCIs, downplayed 2022 "delayed effect" interpretation, added clustering justification with Bertrand et al. citation.
