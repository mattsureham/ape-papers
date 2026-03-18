## Discovery
- **Idea selected:** idea_0949 — NLW wage distribution compression across 379 UK local authorities
- **Data source:** NOMIS ASHE (hourly pay excl overtime, 5 percentiles) — worked perfectly via direct API
- **Key risk:** Only 3 pre-treatment years (2013-2015), confounding from Brexit and COVID

## Execution
- **What worked:** NOMIS API was rock-solid, 22,330 observations returned instantly. Continuous treatment (bite ratio) creates strong variation: 0.28 to 0.84. All percentile effects highly significant (p10 through p60). Robustness to London exclusion, region×year FE, alt bite, and pre-trend placebo.
- **What didn't:** Initial data fetch used wrong pay variable (weekly instead of hourly). Also `nomisr` package not available for R 4.5 — direct API calls worked fine instead.
- **Review feedback noted:** (1) Need event study dynamics to show effects build with rising NLW, (2) p25 > p10 hump pattern needs explanation (ASHE measurement floor?), (3) Brexit migration shock is a plausible confounder correlated with high-bite areas.
