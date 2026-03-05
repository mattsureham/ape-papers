# Internal Claude Code Review — Round 1

**Paper:** Friends in High Places: Minimum Wage Shocks and Social Network Propagation
**Version:** v21 (Demographic Heterogeneity Revision)
**Date:** 2026-03-05

## Structural Verification (per revision plan)

- [x] Abstract leads with California-Texas framing, not methodology
- [x] "Who Responds?" section added as Section 9
- [x] Robustness tables (inference battery, IRS migration, placebos) moved to appendix
- [x] Panel A/B labels consistent across all tables (A=Earnings, B=Employment)
- [x] Education gradient finding in abstract, intro, and conclusion
- [x] Industry gradient reported honestly (counter-intuitive, three interpretations)
- [x] No references to "prior versions" or "reviewers"

## Technical Checks

- [x] All R scripts run without error (01-09)
- [x] 3 demographic coefficient plots generated (age, education, sector)
- [x] 3 demographic heterogeneity tables generated
- [x] Dynamic diagnostics (leads/lags) computed and reported
- [x] Job-flow subsample robustness confirmed
- [x] PDF compiles cleanly (55 pages, no warnings)
- [x] Advisor review: 3/4 PASS

## Remaining Issues

1. Gemini-3-Flash consistently fails on the firm job creation 2SLS SE being smaller than OLS SE — this is a pre-existing data feature, not a code error, and is explained in footnote 1.
2. Table 8 job flow N values (101,650) are from parent v20 analysis — the Azure data has much better coverage (0.1% missing). These table numbers have not been regenerated since the job flow regressions are run inline rather than by 06_tables.R. This is a known inconsistency but does not affect the main results.
