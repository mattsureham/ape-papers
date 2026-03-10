## Discovery
- **Policy chosen:** Switzerland's 2012 Second Homes Initiative (Lex Weber) — large N (400+ treated municipalities), 20+ years pre-data, dual DiD+RDD design, genuinely novel rental-market angle
- **Ideas rejected:** Cantonal minimum wages (small-N concern with only 5 treated cantons), TRAF corporate tax reform (well-studied topic area, continuous treatment intensity with only 26 cantons)
- **Data source:** BFS Leerwohnungszählung (vacancy), BFS PxWeb (demographics/employment), ARE Wohnungsinventar (second-home shares) — all open, no API keys needed
- **Key risk:** Vacancy data may only be available at cantonal level for some cantons; municipality-level coverage to be verified during data fetch

## Review
- **Advisor verdict:** 3 of 4 PASS (after 5 rounds of revision)
- **Top criticism:** Claims about analyses not shown in tables (CS-DiD, covariate balance, merger-exclusion robustness, population heterogeneity numbers without backing table)
- **Surprise feedback:** Codex advisor flagged canton-level clustering as wrong (it's actually MORE conservative than municipality-level, which the code uses). Fixed by adding explicit justification text.
- **What changed:** (1) Softened parallel trends claims, (2) fixed heterogeneity text/table mismatch, (3) added observation counts to all tables, (4) explained N discrepancies across outcomes, (5) acknowledged employment pre-trends limitation, (6) added RDD p-values to table, (7) replaced placeholder contributor names
