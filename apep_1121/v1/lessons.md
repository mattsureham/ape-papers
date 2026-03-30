## Discovery
- **Idea selected:** idea_0938 — Swiss cantonal debt brakes and spending composition
- **Data source:** EFV (Federal Finance Administration) — individual canton Excel files at data.finance.admin.ch. The BFS PXWeb API was a dead end for finance data; the EFV portal was the key.
- **Key risk:** Small N (26 cantons, 4 never-treated). Addressed with wild cluster bootstrap.

## Execution
- **What worked:** The staggered adoption across 11 cohorts gave clean Callaway-Sant'Anna estimation. The null result was precisely estimated and robust across methods. The triple-difference by rule stringency provided the paper's most interesting finding.
- **What didn't:** The BFS PXWeb API for public finance data was inaccessible (HTTP 400/403). Had to discover the EFV portal through web scraping. The opendata.swiss CKAN API also returned 403. Lesson: for Swiss fiscal data, go directly to the EFV.
- **Review feedback adopted:** (1) Added WCB confidence intervals to narrate the informative null. (2) Added caveats about N=2 soft-rule cantons in the triple-difference. (3) Acknowledged capital-vs-current limitation in conclusion. (4) Noted transport pre-trend noise.
