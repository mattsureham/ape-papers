## Discovery
- **Policy chosen:** Five European symmetric reversals (Denmark fat tax, Czech co-payments, Italy RdC, Poland retirement age, France supertax) — chosen because they provide a natural meta-experiment on policy hysteresis across diverse domains
- **Ideas rejected:** Single-country designs lacked the cross-reform comparison needed for the reversal ratio estimand
- **Data source:** Eurostat (HICP, SHA, ilc_li41, lfsq_ergan, lc_lci_r2_q) — all freely accessible via the `eurostat` R package; no API keys needed
- **Key risk:** Small N for meta-regression (only 3 informative reforms after excluding Czech and Italy)

## Execution
- **RR parameterization fix:** Initially compared policy_on to post_repeal for switch-off, which gave wrong RR interpretation. Fixed to compare pre to post_repeal, making RR=0 = full reversal, RR=1 = hysteresis.
- **France pseudo-replication:** Raw data had 193k rows across sectors; needed to filter to total economy aggregate (240 rows). SD(Y) dropped from 44 to 5, fixing SDE from "Null" to "Large negative."
- **Italy limitations:** Only 5 NUTS2 regions × 10 years with 1 post-repeal year. Near-zero β_ON makes RR uninformative. Retained for completeness but excluded from meta-regression.
- **Poland parallel trends:** Placebo test (women vs men 55-59) shows 10pp differential in unaffected groups, severely undermining DiD validity. Acknowledged prominently.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT R1, GPT R2, Codex PASS; Gemini FAIL) — passed on attempt 7
- **Top criticism:** France sample size arithmetic (N=136/196 vs expected 140/200) — resolved by documenting Austria's 4 missing 2008 quarters
- **Surprise feedback:** Poland placebo β=10.18 flagged as fatal error by Gemini even though paper already discussed it honestly; had to add even stronger caveats
- **What changed:** Removed empty meta-regression table and LOO figure (0 d.f. problem); fixed France outcome variable description; harmonized Italy timing; added N column to robustness table; corrected France SD(Y) from 44 to 5
