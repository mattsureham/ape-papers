## Discovery
- **Idea selected:** idea_2157 — UK Pension Freedoms reform, no published evaluation, FCA regulatory data confirmed downloadable
- **Data source:** FCA Retirement Income Market Data (Excel workbooks, 2015-2024) — complex merged-cell structure required Python parsing, not R
- **Key risk:** Descriptive design (no causal identification), only 6 pot-size bands

## Execution
- **What worked:** The data tells an extraordinarily clear story. The pot-size gradient in encashment (88% vs 2%) is so stark that formal regression adds little beyond the raw descriptive statistics. The advice data (2018-24) provides a compelling mechanism. Python/openpyxl was the right tool for the messy Excel parsing.
- **What didn't:** Originally planned RDD at £10K/£30K thresholds, but the data is aggregated into 6 bands — continuous pot values are not available. Had to pivot to log-linear gradient. Clustering by pot-size band (6 clusters) was invalid — switched to period clustering (17 clusters) after reviewer feedback.
- **Review feedback adopted:** (1) Reframed from "causal evaluation" to "comprehensive descriptive analysis" — all three reviewers flagged overclaiming. (2) Switched clustering from pot_size to period. (3) Added welfare sensitivity discussion. (4) Softened "no learning" to "stable cross-sectional relationship." (5) Added caveats about rational encashment (health, liquidity, debt).
