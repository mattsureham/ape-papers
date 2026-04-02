## Discovery
- **Idea selected:** idea_2223 — Government shutdowns × QWI, chosen for novel identification (no existing APEP paper), confirmed Azure data, and DOGE-era policy relevance
- **Data source:** QWI (Azure), QCEW (BLS bulk CSV) — Azure worked via Python DuckDB but not R DuckDB (connection string parsing issue); QCEW needed correct own_code=1 for federal
- **Key risk:** Pre-trends in event study and weak sector decomposition

## Execution
- **What worked:** The pooled DiD is clean and significant (β = -0.066, p = 0.015). Placebo quarter passes. Robust to alternative exposure year and DC/VA exclusion. The dose-response direction is correct (longer shutdown → larger effect).
- **What didn't:** Event-study pre-trends are noisy. Sector decomposition doesn't confirm consumption channel — accommodation/food shows a positive coefficient. The multiplier scaling from the reduced-form coefficient requires assumptions that the paper can't cleanly identify.
- **Review feedback adopted:** Fixed coefficient interpretation (IQR-based magnitudes instead of per-unit claims). Softened multiplier language from "2-3" to "consistent with range." Acknowledged mechanism limitations honestly.
