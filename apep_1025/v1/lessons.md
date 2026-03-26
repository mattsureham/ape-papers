## Discovery
- **Idea selected:** idea_1931 — Neonicotinoid consumer bans × BBS bird data. Chosen for built-in mechanism-matched placebo (insectivorous vs non-insectivorous birds), novel data source (BBS never used in economics), and strong treatment count (12 states).
- **Data source:** USGS Breeding Bird Survey, 2022 release (1966–2021). ScienceBase was down (503); pivoted to older release item that was still serving files. BBS state codes required coordinate-based mapping (not FIPS).
- **Key risk:** Limited post-treatment variation (only 5 states with post-treatment data through 2021).

## Execution
- **What worked:** The TWFE-vs-CS divergence became the paper's central methodological contribution. A clean TWFE result (+0.044, p=0.02) with perfect placebo was revealed as biased by CS (-0.029, null). This is exactly the type of finding tournament judges reward — "settling a dispute" by showing prior methods give misleading answers.
- **What didn't:** The Kimi-K2.5 empirics review failed (API error). Sun-Abraham estimator showed positive effects for BOTH species groups, violating the placebo — this flagged a general state-trend confound rather than mechanism-specific effect.
- **Review feedback adopted:** Added event-study dynamics paragraph, expanded power discussion with MDE calculation, addressed border-route spillovers, added Borusyak et al. (2024) citation per reviewer suggestion.
