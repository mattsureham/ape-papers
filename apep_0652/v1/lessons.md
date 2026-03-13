## Discovery
- **Idea selected:** idea_0155 — EPCS mandates and opioid mortality. Selected for first-order stakes (mortality), strong staggered DiD design (31 treated states), and accessible CDC VSRR Socrata API.
- **Data source:** CDC VSRR Provisional Drug Overdose Deaths (Socrata xkb8-kh2a) + Census ACS population. Year-by-year fetching avoids Socrata pagination limits.
- **Key risk:** Underpowered to detect modest effects given state-year aggregation and high outcome variance.

## Execution
- **What worked:** CDC Socrata API reliable when fetched year-by-year. CS-DiD + Sun-Abraham dual estimation gave sign-instability evidence strengthening the null interpretation. Opioid subtype decomposition (T40.2/T40.4/T40.1) provided built-in mechanism/placebo test.
- **What didn't:** Month field came as text ("January" etc.), requiring manual mapping. Census ACS 2020 1-year was cancelled (COVID), requiring interpolation. Sun-Abraham `aggregate()` returns a matrix not a model object — `coef()`/`se()` fail. Event study SE accessor was `$se.egt` not `$att.egt.se`.
- **Review feedback adopted:** Fixed empty event study Table 3 (SE accessor bug). Tempered null-result language from "mandates fail" to "no detectable effect." Added explicit MDE/power discussion. Changed title to neutral framing. Did not add monthly data or SDUD mechanism test (beyond V1 scope).
