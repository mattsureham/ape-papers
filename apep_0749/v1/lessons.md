## Discovery
- **Idea selected:** idea_0159 — sports betting + DUI enforcement gap; chose for 30+ treated states, FARS data availability, and named mechanism ("game-day externality")
- **Data source:** FARS from NHTSA — bulletproof download, 344K crashes. Census API for population (2020 unavailable, interpolated)
- **Key risk:** DUI arrest data access; ended up dropping enforcement analysis entirely

## Execution
- **What worked:** FARS data is incredibly clean and the game-day triple-diff produced a massive, highly significant interaction (0.92, p<0.001). The non-alcohol placebo was dead zero, exactly as hoped. Event-study pre-trends are flat.
- **What didn't:** Couldn't include DUI arrest data (UCR/NIBRS access uncertain), so the "enforcement gap" promised in the manifest was dropped. All three reviewers flagged this as the #1 issue. Title and framing had to be revised.
- **Review feedback adopted:** (1) Removed "Enforcement Gap" from title, (2) toned down causal claims in abstract/intro, (3) acknowledged game-day definition limitations, (4) made welfare section explicitly illustrative, (5) added confounders discussion, (6) fixed Panel B description (was saying Sun-Abraham, actually TWFE)
- **Key lesson:** When an idea manifest promises a specific data source, verify access BEFORE claiming. The enforcement analysis would have made this paper substantially stronger, but the demand-side game-day externality is still a clear contribution on its own.
