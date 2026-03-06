## Discovery
- **Policy chosen:** France's FTTH rollout (Plan France Tres Haut Debit) + copper decommissioning — staggered deployment across 96 departments with zone-based institutional timing variation
- **Ideas rejected:** (1) Local news consumption patterns — Google Trends regional granularity too noisy for France; (2) Municipal fiscal behavior — diffuse mechanism, long horizons needed
- **Data source:** ARCEP open data (department-quarter FTTH coverage), data.gouv.fr elections (commune-level), GDELT (exploratory)
- **Key risk:** GDELT geographic coding at department level may be too noisy; paper structured to survive on elections alone

## Review
- **Advisor verdict:** 3 of 4 PASS (after 3 rounds of fixes)
- **Top criticism:** Pre-trend placebo rejects (p=0.012), undermining causal interpretation. All three external reviewers flagged this as the central weakness.
- **Surprise feedback:** Election-type mixing (presidential vs European) was flagged as a fundamental design flaw, not just a robustness concern. The sign reversal across election types is the paper's most informative finding.
- **What changed:** (1) Softened all causal language to "associated with"; (2) Fixed critical data bug in European election anti-system vote classification; (3) Added 5 methodology references; (4) Fixed summary statistics, turnout interpretation, balance test sign, jackknife range, and quarter count inconsistencies; (5) Removed spurious election-type×year FE robustness check.

## Summary
- **Key lesson:** When mixing structurally different observation types (presidential vs European elections), the event study will oscillate and identification fails. Either commit to one type or develop a design that handles the heterogeneity.
- **Data lesson:** European election data in France uses nuance codes and list names that vary across years. Always aggregate votes directly rather than grouping by candidate name first — the two-step approach caused a catastrophic 100% anti-system classification bug.
- **Process lesson:** The advisor review is most valuable for catching text-table inconsistencies. Three rounds were needed to eliminate all inconsistencies introduced by the data bug fix.
