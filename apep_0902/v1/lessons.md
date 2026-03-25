## Discovery
- **Idea selected:** idea_1650 — Zero prior literature on RTF laws + QWI data on Azure = high novelty, low data risk
- **Data source:** QWI Parquet on Azure — worked after debugging connection string format (CONNECTION_STRING parameter, not raw string)
- **Key risk:** 14 state clusters for inference (6 treated + 8 control). Wild cluster bootstrap essential.

## Execution
- **What worked:** Staggered DiD with CS estimator ran cleanly after panel balancing. Null result is internally consistent (CS, TWFE, SA all agree). The "shield without a sword" framing makes the null compelling.
- **What didn't:** Smoke test from idea manifest was misleading (MO +59% vs econometric null). Raw descriptive stats can deceive when state-level trends differ. Also, the `sunab()` function returns ALL event-time coefficients (pre and post) — must filter to post-treatment before averaging.
- **Review feedback adopted:** Fixed SA estimate bug (critical), added Roth (2022) pre-trend caveat, kept the footnotesize table fixes for overfull boxes.
