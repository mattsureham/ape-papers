## Discovery
- **Idea selected:** idea_0078 — Opioid day-supply limits and illicit substitution
- **Data source:** CDC NCHS Provisional Drug Overdose Death Counts (xkb8-kh2a) + CDC NCHS Drug Poisoning Mortality (jx6g-fdh6) for pre-2015 total deaths
- **Key risk:** Fentanyl wave confound — differential fentanyl penetration correlated with law adoption

## Execution
- **What worked:** Drug-type decomposition provides built-in mechanism test. Dose-response by limit stringency (3/5/7-day) reveals heterogeneity hidden in aggregate null. 3-day limits show significant substitution effect.
- **What didn't:** CDC provisional data only starts 2015, limiting pre-periods for drug-type analyses. Had to supplement with jx6g-fdh6 for total overdose. Cocaine "placebo" showed unexpected negative effect, weakening the specificity argument. HonestDiD failed due to covariance matrix issues.
- **Review feedback adopted:** Added dedicated dose-response table (Tab 5) as central exhibit. Acknowledged pre-trend issues honestly. Addressed cocaine placebo failure in text. Strengthened limitations discussion.
- **Data engineering notes:** CDC Socrata API uses "12 month-ending" rolling totals — must take latest month per state-year, NOT sum months. Census ACS skipped 2020 1-year due to COVID — interpolate.
