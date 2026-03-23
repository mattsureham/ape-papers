## Discovery
- **Idea selected:** idea_1759 — SNAP drug felon ban rollback across 18 states as natural experiment for employment effects
- **Data source:** QWI sex×education on Azure Parquet — fast fetch (3.1M rows in seconds), excellent coverage
- **Key risk:** Low-education workers as proxy for drug felons introduces measurement error / ITT dilution

## Execution
- **What worked:** Azure QWI Parquet data was exceptionally fast and reliable. The education-specific placebo (E3/E4 null) is clean and compelling. Pre-trends are perfectly flat. The dose-response (full vs partial ban removal) adds credibility.
- **What didn't:** Triple-diff coefficient was collinear with saturated FE — needed to restructure as education-specific DiDs instead. State-level aggregation (48 states, 18 treated) limits power.
- **Review feedback adopted:** Added ITT dilution discussion with BJS prevalence estimates, acknowledged borderline significance explicitly, noted wild cluster bootstrap consistency.
