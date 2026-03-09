## Discovery
- **Policy chosen:** Russia CHPL export controls enforcement — evaluates whether targeted product-level sanctions enforcement actually reduces technology rerouting through transit countries
- **Ideas rejected:** Panama Canal drought (technically competent but not exciting — "ports reshuffled" is predictable), Indonesia nickel ban (only 17 treated districts — small-N is a common tournament loser), US Section 301 tariff exclusions (matching HS10 exclusion lists to trade data proved uncertain)
- **Data source:** UN Comtrade public API at HS6 product level — confirmed accessible without authentication. Mirror statistics approach using transit countries' reported exports to Russia.
- **Key risk:** Annual data resolution means limited post-CHPL observations (only 2024 as full enforcement year). Strategic misreporting by transit countries is a threat to mirror statistics.

## Review
- **Advisor verdict:** 4 of 4 PASS (after 6 iterations fixing fatal errors)
- **Top criticism:** All three referees flagged identification credibility — control group is author-selected, one post-enforcement year is thin, stockpiling/mean-reversion alternative not ruled out. R1 and R2 both demanded wild-cluster bootstrap and permutation inference.
- **Surprise feedback:** R1 and R2 both flagged that β₂ is NOT the 2024 effect — it's the incremental change, with net 2024 effect being β₁+β₂. This was a genuine interpretation error in the original text.
- **What changed:** (1) Scaled back all causal language to "consistent with" throughout, (2) Fixed β₁+β₂ interpretation everywhere, (3) Added permutation inference (p<0.001, 1000 permutations), (4) Reframed tier regressions as descriptive, (5) Elevated PPML to core discussion, (6) Removed redundant Figure 2 and spaghetti Figure 5, (7) Added stockpiling/mean-reversion as explicit threat, (8) Added 5 modern DiD/inference references, (9) Removed "planned research" apologies per prose review.

## Summary
- **Biggest lesson:** The β₂ interpretation error was embarrassing but common in DD designs with sequential treatment indicators. Always explicitly state that the net post-period effect is β₁+β₂ when both indicators are on.
- **What worked:** Product-level Comtrade data at HS6 provides clean treatment variation; permutation inference over product assignments is a powerful complement to clustered SEs with small product samples.
- **What didn't:** Wild-cluster bootstrap (fwildclusterboot) incompatible with fixest models with many FEs. Annual data is too coarse for mid-year policy changes.
- **For next time:** Always compute and report β₁+β₂ alongside individual coefficients. Add permutation inference from the start for small-sample designs. Consider PPML as a co-equal estimator, not a robustness footnote.
