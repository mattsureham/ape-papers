## Discovery
- **Idea selected:** idea_1893 — EGRRCPA exam cycle extension, clean single-date DiD with 445 treated banks
- **Data source:** FDIC BankFind Suite API — free, no key required, 56K bank-quarters fetched cleanly
- **Key risk:** COVID-era forbearance could mask risk-taking effects

## Execution
- **What worked:** FDIC API was seamless, asset-based group assignment straightforward, pre-trends pristine (F=0.74, p=0.675)
- **What didn't:** Net charge-off variable (NTLNLS) had severe scaling inconsistency across bank sizes — 185x difference between groups made it unusable. Dropped from all tables.
- **Review feedback adopted:** Added explicit confidence intervals for the null, added CAMELS selection paragraph acknowledging endogenous selection into treatment, removed NCO from tables
- **Deferred to revision:** Event study figures, CRA Performance data mechanism test, wild cluster bootstrap, narrower control bands ($3B–$5B), heterogeneity by pre-treatment risk
