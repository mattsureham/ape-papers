## Discovery
- **Idea selected:** idea_1441 — Portugal's 2022 golden visa geographic restriction. Picked from random draw; sharp geographic policy lever with 7 years of pre-treatment data.
- **Data source:** INE BPIHE monthly bank appraisal values via JSON API (indicator 0012248). Worked smoothly, 46K records returned covering both NUTS3 and municipality levels.
- **Key risk:** Pre-trend violation between coastal and interior housing markets.

## Execution
- **What worked:** Municipality-level analysis (99 units) was sharper than NUTS3 (26 units). The finer geography revealed a detectable -5.3% effect that NUTS3 aggregation washed out. Tournament lesson confirmed: "aggregation washes out the action."
- **What didn't:** Naive TWFE was badly contaminated by pre-trends. Had to pivot to municipality-specific linear trends. HonestDiD failed due to API mismatch (should investigate proper usage). Wild bootstrap implementation was manual.
- **Key methodological lesson:** With differential pre-trends, the choice of trend specification is everything. Linear trends reversed the sign from +15% to -5%. Placebo tests confirmed the trend spec was adequate, but non-linearity remains a concern.
- **Review feedback adopted:** Reviewers all flagged (1) need for HonestDiD, (2) waterbed test, (3) bootstrap p-values. Adopted bootstrap p-value reporting and cluster count fix. HonestDiD and waterbed test are V2 priorities.
