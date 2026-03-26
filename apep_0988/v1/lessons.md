## Discovery
- **Idea selected:** idea_0149 — Poland's Sunday trading ban provides phased temporal variation (3 phases, 2018-2020) for studying operating-hour restrictions on employment
- **Data source:** Eurostat `nama_10r_3empers` (NUTS-3 employment by NACE section) — GUS BDL API was rate-limited (1000 calls/12h), Eurostat was the reliable alternative
- **Key risk:** COVID confound on Phase 3 (January 2020 = near-total ban, March 2020 = pandemic)

## Execution
- **What worked:** Continuous treatment DiD (trade share × ban intensity) gave a clean framework; cross-country comparison (PL vs CZ/SK) provided a complementary design; placebo sectors clearly diagnosed the identification problem
- **What didn't:** The within-country positive coefficients turned out to be an artifact of differential growth trends (high-trade-share regions = urbanized = faster growth). The public-sector placebo failure was the key diagnostic. Pre-trends in 2013-2015 confirmed the issue.
- **Review feedback adopted:** Softened conclusions from "ban succeeded" to "bounded null" (all 3 reviewers flagged overstatement). Added magnitude bounds discussion. Expanded limitations to acknowledge NACE G-I breadth, annual frequency, and shift-share vulnerability. Did not redo data pipeline — GUS BDL rate limits prevented monthly data access.
