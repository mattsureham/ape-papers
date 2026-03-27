## Discovery
- **Idea selected:** idea_1691 — CROWN Act hair discrimination laws, novel policy with zero existing economics papers
- **Data source:** Census ACS API (tables B20017B/H for earnings, B23002B/H for employment) — reliable, fast, 2014-2023
- **Key risk:** State-level aggregates may be too coarse to detect targeted effects on a subset of Black workers

## Execution
- **What worked:** Triple-difference with state×race, year×race, state×year FE cleanly identifies the treatment. Extended data back to 2014 gave 5 pre-periods. ACS API required no authentication issues.
- **What didn't:** Employment data had Inf values from zero-population cells; required min-population filter. The 2020 ACS gap creates a hole in the panel.
- **Review feedback adopted:** Added MDE paragraph (7.5% detectable), clarified FE identification, better framed female interaction null, explained t+3 cohort-driven negative.
- **For V2:** PUMS microdata would allow individual-level regressions, occupation heterogeneity, and much sharper tests. All three reviewers recommended this.
