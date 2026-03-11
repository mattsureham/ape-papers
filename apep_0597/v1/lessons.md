## Discovery
- **Policy chosen:** Nigeria's 2023 fuel subsidy removal — $10bn/year policy with immediate 129% price shock, highest-salience reform in recent SSA history
- **Ideas rejected:** Electricity privatization (idea_0218, only 2 pre-periods), CBN FX ban (idea_0148, angle overlap with in-progress apep_0595), TSA (idea_0222, NEEDS_WORK status)
- **Data source:** NBS monthly PMS Price Watch + Transport Fare Watch (freely downloadable), World Bank GHS-Panel Wave 5 (publicly listed)
- **Key risk:** NBS monthly reports may require manual PDF scraping; GHS-Panel Wave 5 microdata may need WB account registration. Distance measure assumes terminal-to-state-capital captures distribution cost variation.

## Review
- **Advisor verdict:** 4 of 4 PASS (after 9 rounds; rounds 1-8 had various internal consistency issues)
- **Top criticism:** Food price identification lacks event study, commodity-by-month FE, and spatial inference correction
- **Surprise feedback:** Both GPT reviewers flagged cereal magnitude (7x petrol) as suspicious — valid concern that led to useful reconciliation discussion
- **What changed:** Added food event study (Figure 8), Conley SEs, commodity-by-month FE, Roots/Tubers column in Table 3, softened causal language, magnitude reconciliation subsection
