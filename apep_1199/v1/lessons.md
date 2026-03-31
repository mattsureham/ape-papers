## Discovery
- **Idea selected:** idea_1882 — Brazil's 2020 Marco Legal do Saneamento and waterborne disease. Chose from random draw of 10 based on large N (350+ treated municipalities), strong administrative data (DATASUS), and first-order policy question.
- **Data source:** DATASUS SIH via pysus + IBGE population API — BigQuery was down (permissions issue), pivoted to direct pysus download. Very slow (2+ hours for 6 states × 8 years). SNIS API also unavailable.
- **Key risk:** COVID-era confounding + pre-existing differential trends in treated vs control municipalities.

## Execution
- **What worked:** Treatment panel construction from known BNDES auction records was clean. IBGE population API worked perfectly. The Callaway-Sant'Anna estimator ran without issues. Honest framing of null/mixed results — tournament rewards intellectual honesty.
- **What didn't:** BigQuery permissions blocked initial data strategy. Pysus download was painfully slow. Pre-trends failed badly (p=0.00) — significant differential trends at t-5 and t-3. HonestDiD failed due to matrix dimension issues. SNIS investment data unavailable for mechanism tests.
- **Review feedback adopted:** All 3 reviewers flagged pre-trends as fatal. Paper was already rewritten to acknowledge this honestly and frame heterogeneity as the contribution rather than claiming clean causal effects. Added emphasis on Corsan/South subsample as cleanest result. Removed "investment dividend" language. Explicitly qualified all causal claims.
