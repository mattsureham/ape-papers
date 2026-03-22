## Discovery
- **Idea selected:** idea_1712 — Tribal casino revenues and opioid epidemic (first cause-specific decomposition)
- **Data source:** CDC NCHS (state-level OD rates), VSRR (county-level), Census ACS (AI/AN demographics), Federal Register API (compact dates)
- **Key risk:** County-level AI/AN mortality data is inaccessible at scale (CDC WONDER no bulk API, suppression at <10 deaths). Forced pivot to state-level design.

## Execution
- **What worked:** Federal Register API cleanly returned 448 gaming compact notices. State-level CDC data merged well with treatment assignment. The triple-difference design (gaming × AI/AN share × opioid wave) produced a clean, interpretable result.
- **What didn't:** Original plan for county-level AI/AN-specific mortality was infeasible. CDC WONDER has no bulk download API, and county-level AI/AN overdose counts are almost always below the 10-death suppression threshold. Had to redesign around state-level aggregates.
- **Key finding:** Gaming states have 4.8 fewer OD deaths per 100K overall (protective), but during the synthetic opioid wave, high-AI/AN gaming states saw a +7.4 reversal (p<0.01). Casino income appears to fund infrastructure (protective for all) while increasing disposable income in vulnerable AI/AN communities (enabling during fentanyl).
- **Review feedback adopted:** Strengthened limitations section to explicitly acknowledge ecological fallacy, cross-sectional identification weakness, and missing Medicaid expansion controls. All three reviewers flagged the state-level aggregation as the primary weakness — a fair criticism that reflects genuine data constraints.

## Lessons for Future Papers
- **CDC WONDER is NOT a bulk data source.** Don't plan county-level race-specific mortality analyses without restricted-use data access. The web interface works for manual queries but cannot be scripted.
- **AI/AN populations are too small** for county-level statistical analysis in most US counties. Any AI/AN health paper needs to either (a) use restricted-use NCHS microdata, (b) aggregate to IHS service areas, or (c) work at the state level with appropriate caveats about ecological inference.
- **The income-health relationship is sign-ambiguous** during supply-side shocks. This connects to Doleac & Mukherjee (2022) on naloxone moral hazard. Future papers on income transfers and health should consider whether the drug supply environment moderates the effect.
