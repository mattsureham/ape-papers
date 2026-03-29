## Discovery
- **Idea selected:** idea_0146 — Romania's overnight payroll tax shift (the most extreme statutory incidence reversal in European history)
- **Data source:** Eurostat LCI (lc_lci_r2_q) — clean quarterly API, 2.89M rows, no API key needed
- **Key risk:** Single-treated-country design with only 6 clusters

## Execution
- **What worked:** The Eurostat `eurostat` R package fetched data smoothly after fixing column name (TIME_PERIOD not time) and adding unit filter (I20). Effect magnitude is self-identifying — no ambiguity in the results. The non-wage share is the cleanest outcome because it's unaffected by minimum wage confounds and doesn't depend on the 2020-indexed level.
- **What didn't:** Three-way FE specification (country×sector + country×quarter + sector×quarter) absorbs the treatment variable since it only varies at country×time. Had to simplify to country×sector + quarter FE. Event study parsing broke because fixest row names use `event_time::-4:treated_country` format, not just the number.
- **Review feedback adopted:** (1) Sharpened the interpretation from "market incidence" to "regulatory enforcement of incidence neutrality" — honest about what the mandate means. (2) Added t(5) inference discussion for 6-cluster setting. (3) Added minimum wage confound section explaining why NW share is unaffected. (4) Added footnote explaining Romania's extreme NW index values (2020-basing artifact). (5) Expanded limitations section.
- **Key lesson:** When you have 1 treated unit and a massive effect, the permutation test and t(df) correction are essential — but with t-stats above 13, even the most conservative corrections don't matter. The real challenge is interpretation, not inference.
