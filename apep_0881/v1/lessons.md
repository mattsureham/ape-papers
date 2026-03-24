## Discovery
- **Idea selected:** idea_0960 — England's academy programme is the world's largest school autonomy experiment; staggered adoption of 11,000+ schools provides massive DiD design
- **Data source:** GIAS (Get Information About Schools) — bulk CSV downloads from DfE; annual snapshots only available from 2021+ (earlier years return 404)
- **Key risk:** Academy conversions create new school URNs, breaking panel continuity; required predecessor-successor linkage from GIAS links file

## Execution
- **What worked:** GIAS predecessor links (17,118 records) successfully bridged maintained→academy URN changes; fixest::sunab() handled 70K obs panel smoothly where did::att_gt() segfaulted
- **What didn't:** EES API was completely non-functional (all endpoints 404); GIAS undated URL returned 500 (had to discover dated URL pattern); pre-2021 snapshots unavailable, limiting panel to 6 years
- **Review feedback adopted:** [pending review completion]

## Key findings
- Sun-Abraham ATT: -0.34pp FSM share (p=0.031) — academy conversion reduces disadvantaged pupil share
- TWFE sign-flip: +0.22pp — textbook forbidden-comparison bias
- Sponsor-led academies drive the effect (-1.21pp, p=0.004); converter academies are null
- LA-level: more academies → less measured segregation (counterintuitive)
