## Discovery
- **Idea selected:** idea_0639 — Mexico's Sorteo Militar lottery and youth crime victimization
- **Data source:** ENVIPE victimization survey (2021-2024) via INEGI, SESNSP victim data via GitHub mirror
- **Key risk:** Identification relies on Male × Age 18-19 interaction, which captures lottery effects PLUS other age-18-specific gender transitions

## Execution
- **What worked:** ENVIPE microdata has individual-level age, sex, and crime victimization — ideal for the cross-age DiD
- **What didn't:** INEGI mortality microdata URLs are all broken (website reorganization); SESNSP data moved to SharePoint requiring authentication. Had to pivot data strategy entirely.
- **Data lesson:** Always have fallback data sources. The ENVIPE `conjunto_de_datos` URL pattern (new as of 2021+) works; old `microdatos` pattern is dead.
- **Review feedback adopted:** Tempered policy claims from "does not reduce crime" to "cannot detect large reductions"; strengthened fraud placebo discussion; added power benchmarks against Blattman (2017) CBT program
- **Key insight:** The fraud placebo failure (β = -0.014, SE = 0.005) is the paper's most honest contribution — it reveals that cross-age gender DiD designs at age thresholds with multiple concurrent transitions (drinking age, labor market entry, financial market access) face fundamental identification challenges
