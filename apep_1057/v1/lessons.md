## Discovery
- **Idea selected:** idea_0747 — Water system consolidation effects on receiving systems
- **Data source:** EPA SDWIS via Envirofacts API — bulk downloads returned 404; API state-by-state was slow but worked; violations had no STATE_CODE column so had to download all 314K at once
- **Key risk:** ZIP-code matching introduces severe measurement error; reviewers unanimously flagged this

## Execution
- **What worked:** EPA Envirofacts API for national water systems data (94K systems, 314K violations). Staggered DiD with Callaway-Sant'Anna. Clean pre-trends (0/8 significant). Well-powered null with clear policy implications.
- **What didn't:** Initial attempt at ECHO bulk downloads returned 404. Envirofacts API was very slow per-state (~40 min for violations). ZIP matching assigns treatment to all active systems in a ZIP, not just the actual receiver — all 3 reviewers flagged this as the primary limitation.
- **Review feedback adopted:** (1) Toned down abstract claim about "supporting EPA rule" — null is informative but measurement error caveat is important; (2) Better explained 5K vs 40K deactivation discrepancy; (3) Expanded Poisson discussion to explain extensive/intensive margin divergence; (4) Added MDE framing to confidence intervals.

## Key Insights
- **Null results need framing discipline:** A null is only interesting if you can say what it rules out. The 95% CI ruling out >75% increases from baseline is the key deliverable.
- **EPA Envirofacts API quirks:** VIOLATION table has no STATE_CODE column; COUNT endpoint ignores filters. State filtering only works on WATER_SYSTEM table. For violations, must download all and filter by PWSID prefix.
- **Poisson vs OLS divergence:** When outcome is rare (2% violation rate), Poisson on selected sample (systems with ≥1 violation) can show significant effects while OLS on full sample shows null. This extensive/intensive margin distinction matters for policy interpretation.
