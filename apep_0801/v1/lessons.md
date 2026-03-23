## Discovery
- **Idea selected:** idea_1633 — California SB 328 school start time mandate, first statewide test of sleep-and-safety hypothesis
- **Data source:** NHTSA FARS (bulk CSV download, 2015-2023) + Census ACS — both reliable and fast to acquire
- **Key risk:** Single treated unit (California) with sparse outcome (15-20 teen morning fatalities/year)

## Execution
- **What worked:** Triple-layered identification (TWFE, SDID, triple-diff) with permutation inference provided a complete picture; the gap between conventional and permutation p-values (0.001 vs 0.59) became the paper's strongest finding
- **What didn't:** The synthdid R package had installation issues (GitHub auth) and SE computation failed; had to install from zip and report SDID without SE
- **Review feedback adopted:** Fixed mean inconsistency (Table 1 vs text), added back-of-envelope lives calculation, added MDE/power discussion, strengthened compliance heterogeneity discussion, softened conclusion language from "absence of effect" to "cannot detect"
- **Key lesson:** With rare outcomes and one treated unit, the paper becomes about inference methodology as much as the policy question — lean into that framing rather than fighting it
