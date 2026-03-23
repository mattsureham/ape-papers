## Discovery
- **Idea selected:** idea_0483 — EU posted workers → far-right voting in France. Selected for clean institutional lever (EU enlargement), novel services-trade channel, and available data (DARES + elections + Eurostat).
- **Data source:** data.gouv.fr (elections), Eurostat nama_10r_3empers (employment), DARES national statistics (posted workers). DARES website blocked by CAPTCHA — used published statistics instead.
- **Key risk:** Pre-trends in exposed départements; NUTS2→département employment data imputation.

## Execution
- **What worked:** The manufacturing placebo is the paper's strongest result — construction/agriculture predict FN growth, manufacturing doesn't. This within-département sector decomposition is clean.
- **What didn't:** The Bartik instrument is collinear with year FE (insignificant with FE). The main DiD specification (exposure × post) doesn't survive exposure-specific linear trends (drops from 50 to 9, insignificant). Pre-trends are real and non-trivial.
- **Review feedback adopted:** All three reviewers flagged pre-trends and NUTS2 measurement. Softened causal language throughout, added exposure-trend specification to robustness, clarified NUTS2 limitation in data section. Reframed as "suggestive evidence of non-tradable channel" rather than clean causal claim.
- **Key lesson:** When pre-trends exist, run the trend-controlled specification BEFORE writing the paper, not after reviews. Would have led to more appropriately framed results from the start.
