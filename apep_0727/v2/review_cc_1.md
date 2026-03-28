# Internal Review (Claude) — Round 1

## Text-Table Consistency Check

- [x] b = 86.5 matches Tab 2 and Tab 5 baseline (degree 7, [9.0, 11.0))
- [x] DiB = 84.7, t = 87.7 matches Tab 2 Panel B
- [x] Excess mass 134,524 matches Tab 2
- [x] Annual estimates in Tab 3 match data/bunching_10_annual.csv
- [x] Period labels consistent across text, Tab 1, Tab 2, Tab 3
- [x] Module count medians (32 vs 39-44) match Tab 4 Panel B
- [x] Kink contribution 22.0, notch contribution 32.3 match Tab 4 Panel A
- [x] Robustness ranges (58-87 poly, 55-144 window) match Tab 5
- [x] Welfare arithmetic: 134,524 × 1 = 135 MW, × 2 = 269 MW, × 3 = 404 MW — text says 135-270 MW (conservative to central), consistent
- [x] N = 3,017,639 matches Tab 1 total
- [x] 62,000 at 9.9 kWp, 87 at 10.1 (intro) — from bin counts, surcharge period: n_99 = 61,979 ≈ 62,000, n_101 = 87. Correct.

## Claims Check

- [x] "order of magnitude larger" — b = 87 vs Saez 2-3, Kleven 4-8: yes, 10-40x
- [x] "four-break" — four distinct regimes with predicted direction changes: correct
- [x] Post-2021 language: "attenuates" not "vanishes" — fixed per Codex feedback
- [x] Module count: "fewer panels" not "one fewer panel" — fixed
- [x] Ground-mount: acknowledged as suggestive, N=325 noted — correct

## Issues Remaining

- The 7 kWp placebo (b=474) gets a paragraph of explanation but no DiB test. Should compute the 7 kWp difference-in-bunching (2014-2020 minus 2008-2011) to show it's technological, not policy-driven.
- The welfare section could benefit from a sensitivity table in the appendix.
- References are thin — only 8 citations. Need to expand the bibliography.

## Verdict

Ready for external review pipeline. The text-table alignment is correct after the integer-bin reconciliation. The remaining issues are refinements, not blockers.
