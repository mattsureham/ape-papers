## Discovery
- **Idea selected:** idea_1647 — Right-to-repair laws are a genuinely novel regulatory area with zero published empirical evaluations, despite enormous policy attention
- **Data source:** BLS QCEW API — clean, fast, fully balanced panel with no disclosure suppressions
- **Key risk:** Only 5 treated states, making inference with few clusters the binding constraint

## Execution
- **What worked:** QCEW data fetched cleanly in one pass. CS-DiD ran without issues. The placebo (NAICS 8111) provided a strong validation. The theoretical ambiguity made the null result genuinely informative rather than just underpowered.
- **What didn't:** Pre-trends for establishments showed mild positive drift at long horizons, weakening that outcome as a primary result. Employment (clean pre-trends) became the more credible headline. The wage effect was suggestive but didn't survive WCB — honest reporting required de-emphasis.
- **Review feedback adopted:** Elevated employment as primary outcome over establishments; added explicit acknowledgment that NAICS 8112 includes precision instruments (measurement dilution); added enforcement caveat in discussion; strengthened parallel trends language.
