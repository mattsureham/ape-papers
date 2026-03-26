## Discovery
- **Idea selected:** idea_1446 — Ban-the-Box and the Black employment gap; chosen for first-order welfare question, clean staggered adoption, and QWI race panel novelty
- **Data source:** QWI county×race panel from Azure Blob Storage — connection string escaping issue (shell semicolons truncate env vars); must read .env directly in R
- **Key risk:** County-level aggregation may dilute subpopulation effects detectable in microdata

## Execution
- **What worked:** Azure data fetch was fast once connection fixed. 9.1M row panel with 3,089 counties, 548 treated. Clean pre-trends (0/11 significant). Leave-one-out stable. Public-sector placebo correctly null.
- **What didn't:** CS-DiD `did::att_gt()` failed due to panel balance and memory issues; switched to `fixest::sunab()` at state level. Wild cluster bootstrap exceeded 16GB memory limit.
- **Review feedback adopted:** Populated empty CS-DiD table with Sun-Abraham ATTs. Added power analysis paragraph (MDE ~0.64 log points). Fixed WCB p-value display. Corrected data description (QWI rh/ns extended tabulation, not standard public files). Added formal pre-trend F-test.
