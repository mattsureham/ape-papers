## Discovery
- **Idea selected:** idea_0481 — CSE reform and far-right voting, chosen for vivid policy puzzle (voice displacement → populism), large N (34,446 communes), and confirmed data access
- **Data source:** INSEE Sirene (Parquet, 2.15GB) + data.gouv.fr election results (2012/2017/2022). All freely available. Sirene processed efficiently via arrow in R.
- **Key risk:** Treatment measured from 2026 Sirene stock, not 2017 vintage. Classical measurement error attenuates toward zero, but non-classical bias possible if threshold-crossing correlates with political trends.

## Execution
- **What worked:** Clean data pipeline across three different file formats (CSV, XLS wide, CSV long). Balanced panel of 34,446 communes. Clean pre-trends for the main outcome (Le Pen). Precisely estimated null is a genuine contribution — rules out effects >1pp.
- **What didn't:** The Mélenchon "finding" had violated pre-trends (significant 2012 coefficient), invalidating causal interpretation. The election-cycle structure (5 years between observations) limits pre-trend testing to a single comparison.
- **Review feedback adopted:** Added explicit MDE/power discussion, strengthened measurement error and ecological inference discussion, addressed anticipatory effects concern. All three reviewers flagged the same core issues — treatment timing, ecological fallacy, limited pre-periods.
