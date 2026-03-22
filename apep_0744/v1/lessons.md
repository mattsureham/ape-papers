## Discovery
- **Idea selected:** idea_1017 — Wales's overnight 20mph default creates the cleanest country-level speed limit natural experiment
- **Data source:** DfT STATS19 — downloaded cleanly, 503K collisions. Column names changed from `accident_*` to `collision_*` in recent DfT releases.
- **Key risk:** Few treated clusters (22 Welsh LAs) limits power for randomization inference

## Execution
- **What worked:** The placebo test on >40mph roads provides strong within-setting validation. Severity composition effect (KSI share rising while counts fall) is a genuine insight that monitoring reports miss.
- **What didn't:** COVID-era quarters (2020) introduce noise in the event study pre-trends. Excluding 2020 reduces the point estimate from -3.98 to -3.00 but it remains significant.
- **Review feedback adopted:** Fixed Poisson interpretation (exp(-0.197)-1 = -17.9%, not -19.7%), added excluding-2020 robustness check, softened significance claims given RI p-values of 0.11-0.14. Reviewers wanted spatial RDD and property value analysis — deferred to V2 scope.
