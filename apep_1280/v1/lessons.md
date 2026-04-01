## Discovery
- **Idea selected:** idea_1189 — MW + racial gap using QWI race×industry files. First attempt (idea_2097, REACH bunching) failed: ECHA behind Azure WAF, data inaccessible.
- **Data source:** QWI rh/n3 from Azure — 6.5M rows in 22 seconds via Python DuckDB (R DuckDB Azure connection failed due to secret creation issues)
- **Key risk:** State-level aggregation reduces sample from 6.5M to 7.3K; reviewers unanimously flagged this

## Execution
- **What worked:** DDD design cleanly isolates MW effects on racial gap (β=0.169***); high-wage placebo validates identification; decomposition adds value (employment + earnings)
- **What didn't:** R DuckDB Azure extension; first idea entirely; CS-DiD had small-group warnings
- **Review feedback adopted:** Fixed treated state count inconsistency (17→25); added justification for state-level aggregation; explained TWFE vs DDD sign flip using placebo evidence; added bootstrap iteration count
