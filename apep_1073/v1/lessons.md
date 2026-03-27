## Discovery
- **Idea selected:** idea_0682 — BRAC base closures, first modern staggered DiD with QWI
- **Data source:** Census QWI from Azure (6.4M rows, 33 GB), BRAC treatment list from DoD reports
- **Key risk:** QWI starts 1993 but BRAC rounds go back to 1988 — limited pre-treatment data

## Execution
- **What worked:** Industry decomposition is the key contribution — manufacturing down, accommodation up, healthcare flat. Named phenomenon "conversion penalty" captures the insight precisely.
- **What didn't:** Callaway-Sant'Anna completely failed with 6 treated units per cohort. Pre-trends in total employment levels are violated. Had to pivot from CS to Sun-Abraham + TWFE.
- **Data lesson:** Azure connection string with semicolons gets truncated by shell — must parse .env directly in R.
- **Review feedback adopted:** Added private-sector caveat (Gemini), clarified sample sizes (Codex), strengthened pre-trends honesty (all three), noted industry shares as primary estimand. Dose-response and worker-flow analyses are V2 improvements.
