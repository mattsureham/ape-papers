## Discovery
- **Policy chosen:** Civil asset forfeiture reform (2014-2021, 27 states) — bipartisan wave with clean staggered timing, understudied mortality outcome
- **Ideas rejected:** FBI arrest data (API inaccessible, 403 on all endpoints), police staffing/budgets (data too sparse at state level)
- **Data source:** CDC NCHS (1999-2015) + VSRR (2016-2022) via Socrata API — gold standard mortality data, complete coverage
- **Key risk:** Concurrent opioid policies (naloxone, PDMPs) could confound; addressed via dose-response gradient specific to forfeiture intensity
- **Major pivot:** Originally planned to study police enforcement reallocation (arrests by crime type); FBI CDE API returned 403 on all endpoints. Pivoted to drug overdose mortality — actually stronger because it's the first-order outcome critics predicted would worsen.

## Execution
- **Data challenge:** CDC NCHS only covers 1999-2015; found VSRR dataset covering 2016-2022 to extend panel
- **Census API quirk:** .env loading order mattered — had to add .env parser at top of 01_fetch_data.R
- **HonestDiD failed:** Singular covariance matrix (likely insufficient pre-treatment variation for relative magnitudes approach). WCB syntax: `clustid` requires formula (~state_fips), not vector
- **Surprising result:** Reform REDUCES mortality (opposite of critics' prediction). Dose-response gradient is clean and monotonic.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT R1, Gemini, Codex — after 7 rounds)
- **Top criticism:** Internal consistency across sample sizes (summary stats 900 vs regression 1200) and mean values (14.9 vs 18.3) — needed careful reconciliation
- **Surprise feedback:** Gemini flagged that event-time e=6 is only identifiable from early cohorts (2014-2016) — valid concern, added clarification. Also caught that covariates were described in text but not actually used in regressions.
- **What changed:** (1) Replaced placeholder metadata, (2) Added N rows to dose/robustness tables, (3) Switched percentage denominator from 18.3 to 14.9 (estimation sample mean), (4) Clarified covariates are descriptive only, (5) Added timing_data.tex, (6) Populated empty Appendix E with supplementary figures
