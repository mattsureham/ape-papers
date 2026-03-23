## Discovery
- **Idea selected:** idea_0641 — QWI quarterly H-1B dynamics via DDD; chosen for strong methodology (triple-diff praised by judges), rich public data, and clear economic object (adjustment speed)
- **Data source:** Census QWI via Azure blob storage — no API issues, 5.2M rows fetched via Python DuckDB (R Azure extension had curl incompatibility)
- **Key risk:** Pre-trend contamination from dot-com bust affecting young tech workers differentially

## Execution
- **What worked:** DDD design cleanly separated complementarity from substitution; earnings result was highly robust (p=0.003 even after truncating to pre-crisis); quarterly event study showed clear deepening trajectory
- **What didn't:** R DuckDB Azure extension fails with curl error — had to route through Python for data fetch; initial sample included Great Recession which inflated effects
- **Review feedback adopted:** (1) Truncated sample to 2007Q3 per deepseek reviewer's concern about crisis confound — results strengthened; (2) Added earnings event-study column per all three reviewers; (3) Improved mechanism discussion to acknowledge reduced-demand alternative alongside complementarity; (4) Updated mining placebo which became even cleaner null (0.034, p=0.91)
- **Surprise:** All DDD coefficients were negative — expected substitution (positive for natives), got complementarity. The data told a different story than the initial framing anticipated.
