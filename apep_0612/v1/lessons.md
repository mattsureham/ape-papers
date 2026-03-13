## Discovery
- **Idea selected:** idea_0080 — Immigration judge leniency IV for crime. Novel design, first-order stakes.
- **Data source:** OpenImmigration.us (free JSON APIs, reliable) + CDC Mapping Injury (Socrata API) + ACS tidycensus
- **Key risk:** Cross-sectional IV violates exclusion restriction — judge composition correlated with state demographics

## Execution
- **What worked:** Data APIs all returned cleanly. First stage extremely powerful (F > 2,889). Multiple placebo tests support null interpretation.
- **What didn't:** FBI Crime Data Explorer API requires authentication (DEMO_KEY rejected). Had to use CDC homicide data instead of full UCR crime data. Only 29 states have both immigration courts and complete data.
- **Balance test failure:** Judge leniency significantly predicts poverty rate, foreign-born share, and median income. Cross-sectional design cannot satisfy exclusion restriction without conditioning on observables.
- **Design lesson:** The judge-IV framework works best at the case level (within-court random assignment). Aggregating to state level sacrifices the identifying variation. A panel design exploiting judge turnover would be stronger.
- **Review feedback adopted:** All 3 reviewers flagged cross-sectional exclusion restriction failure and treatment dilution. Adopted: (1) MDE/power calculation in Discussion, (2) explicit treatment intensity math (0.3 asylum recipients per 100k per pp grant-rate increase), (3) acknowledgment that first-stage F is mechanical not informative, (4) terminology clarification (judge leniency vs grant rate), (5) HC1 vs HC3 note, (6) excluded-states documentation in appendix. Not adopted: within-court redesign (infeasible for V1 without EOIR case-level data).
