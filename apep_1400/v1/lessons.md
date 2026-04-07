## Discovery
- **Idea selected:** idea_2413 — PFL × racial hiring gap, competing mechanisms (statistical discrimination vs. cost-spreading)
- **Data source:** Census QWI API (race microdata) — Azure blob storage was broken, pivoted to direct API calls
- **Key risk:** Small number of treated states (8, reduced to 6 in balanced panel)

## Execution
- **What worked:** CS-DiD produced clean pre-trends and a striking asymmetry (hiring diverges while wages converge). The generosity heterogeneity is the real contribution — high-generosity programs avoid the discrimination trap entirely.
- **What didn't:** Industry-level analysis infeasible due to QWI suppression at state×industry×race level. Azure connection broken. Quarterly panel too large for CS-DiD bootstrap, had to aggregate to annual.
- **Review feedback adopted:** Added gender limitation discussion, COVID confounding analysis, industry aggregation justification, and sharpened the opening hook per prose reviewer.
