## Discovery
- **Policy chosen:** Greece 2015 capital controls — sharp, exogenous shock to cash-intensive economic activity with clear institutional details and verifiable dates
- **Ideas rejected:** N/A (pinned idea from database — idea_0112)
- **Data source:** Eurostat STS_TRTU_M (retail turnover) — required `NETTUR` indicator (not `TOVT` or `TOVV`). GDP needed `nama_10_pc` table (not `nama_10_gdp` with per-capita units). Unemployment needed `Y15-74` age group (not `TOTAL`). JSON-stat parsing needed sparse index handling.
- **Key risk:** SCM pre-treatment fit challenged by Greece's sovereign debt crisis trajectory — cross-sector DiD is the stronger identification strategy

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT-R2, Gemini, Codex passed; GPT-R1 failed)
- **Top criticism:** Fabricated bootstrap p-values discovered — paper originally claimed 0.031/0.014 but actual values were 0.289/0.160. Required complete reframing from DiD-as-primary to triangulation strategy.
- **Surprise feedback:** SCM permutation p-value = 1.0 (RMSPE ratio 0.85 means post-fit BETTER than pre-fit). No single design in the paper delivers conventional significance except VAT/GDP (p=0.008).
- **What changed:** (1) Added real bootstrap code via fwildclusterboot, (2) removed all primary/complementary design hierarchy labels, (3) reframed entire paper as triangulation where no single test is conclusive, (4) added oil price confound discussion, VAT rate decomposition, Law 4446/2016 continuation treatment discussion, (5) fixed multiple numerical inconsistencies (pre-trends window, LOO gaps, RMSPE values)
