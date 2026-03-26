## Discovery
- **Idea selected:** idea_0550 — EU Payment Accounts Directive, first causal evaluation using staggered transposition
- **Data source:** Eurostat JSON-stat API (internet banking, isoc_ci_ac_i) + World Bank Global Findex + ECB MIR
- **Key risk:** Never-treated comparison group (CZ/HU/SK/SI) on faster digital convergence trajectory

## Execution
- **What worked:** Eurostat JSON-stat API gave 17 years of annual data (2003-2025) — far richer than Findex's 5 waves. Pre-trends were clean. Staggered DiD with 3 cohorts (2015/2016/2017) and 4 never-treated provided strong identification structure.
- **What didn't:** The ECB payment statistics (PSS) direct download failed — unclear API keys. The Eurostat R package had stale dataset IDs (isoc_bde15cbc → 404). Had to use direct REST JSON-stat endpoint.
- **Key insight:** The negative treatment effect (-5.3pp) evaporated when excluding never-treated countries (-1.0pp, insignificant). The "mandate gap" is really about differential digital convergence between Central European early-movers and the rest of the EU.
- **Review feedback adopted:** (1) Added not-yet-treated-only CS-DiD as key robustness check; (2) Softened statistical claims given WCB p=0.162; (3) Acknowledged extensive vs. intensive margin distinction; (4) Added Sun-Abraham aggregate estimate to robustness table.
