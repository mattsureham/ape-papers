## Discovery
- **Idea selected:** idea_1346 — QWI race-ethnicity panel for MW racial hiring effects; novel data source for an old question
- **Data source:** Azure-hosted QWI parquet (race-ethnicity panel, all-industry county totals) + DOL/Lislejoem MW panel
- **Key risk:** QWI cell suppression at county × race level — mitigated by aggregating across industries

## Execution
- **What worked:** The DDD with county-level bite variation provided far more power than the state-level CS event study. The triple interaction (Black × Post × HighBite) was the cleanest result.
- **What didn't:** The benzipperer/minimum-wage-data URL has moved to `historicalminwage` repo. Needed to fall back to Lislejoem dataset + manual 2021-2023 supplement. The continuous Kaitz index specification was imprecise (p=0.20) — binary tercile was cleaner.
- **Key discovery:** Adding state × quarter FE doubled the triple interaction coefficient (0.139 → 0.338), meaning unobserved state-level shocks were attenuating the effect. This was flagged by all three reviewers and made the paper substantially stronger.
- **Review feedback adopted:** State × quarter FE as preferred specification; toned down discrimination mechanism claims; clarified log-point vs percentage language
