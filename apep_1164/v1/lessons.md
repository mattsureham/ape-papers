## Discovery
- **Idea selected:** idea_0255 — Colombia ETPV regularization of 1.8M Venezuelan migrants, studying formalization spillovers
- **Data source:** DANE GEIH Department Annex (published aggregates) + Migración Colombia ETPV pre-registration API (datos.gov.co). Individual-level GEIH microdata was inaccessible due to CAPTCHA requirements.
- **Key risk:** Aggregate data cannot separate native from immigrant workers or formal from informal employment

## Execution
- **What worked:** The datos.gov.co Socrata API provided 2.46M ETPV records with department-level breakdowns — excellent treatment variable. DANE department annexes have clean 2007-2024 time series for 23 departments.
- **What didn't:** DANE microdata portal requires CAPTCHA, forcing pivot to published aggregates. This prevented direct measurement of informality — the paper's original research question. Annual (not monthly/quarterly) frequency limited statistical power.
- **Review feedback adopted:** Strengthened discussion of aggregate-vs-formality measurement gap. Added explicit acknowledgment that binary post indicator attenuates effects (staggered rollout). Added discussion of compositional shifts hidden by aggregate data. Referenced CS-DiD as improvement for future work.
