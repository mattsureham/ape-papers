## Discovery
- **Idea selected:** idea_0884 — EU ATAD interest limitation rule exploiting de minimis threshold variation across 27 countries
- **Data source:** Eurostat Annual Sector Accounts (nasa_10_f_bs, nasa_10_nf_tr) — smooth fetch, good coverage
- **Key risk:** Country-level aggregation (N=27) limits power; MDE at ~50% of pre-treatment SD

## Execution
- **What worked:** Dose-response design with de minimis variation is clean. Event study pre-trends flat. Derogation placebo validates perfectly. The Eurostat R package made data acquisition seamless.
- **What didn't:** Inflation data unit name was `RCH_A_AVG` not `RCH_A` — cost one debugging round. Column names in Eurostat changed (`TIME_PERIOD` not `time`). The `fwildclusterboot` package requires cluster info from the model object, not a character arg.
- **Review feedback adopted:** (1) Added net interest outcome (D41 PAID - RECV) per Gemini; (2) Nuanced MDE interpretation — rules out large effects, not small ones; (3) Elevated the 3M threshold group result (-2.5pp, p<0.10) from footnote to main discussion — possible evidence ATAD works in modal countries but dose measure may be wrong; (4) All reviewers wanted figures (event study plot) but V1 format = zero figures.
