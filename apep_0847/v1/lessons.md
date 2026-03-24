## Discovery
- **Idea selected:** idea_0954 — UK stop smoking service austerity with Bartik IV
- **Data source:** Fingertips API (OHID) + DHSC grant allocation files from GOV.UK
- **Key risk:** Single pre-period for quit rates (2013/14 only); convergence confound from needs-based grant formula

## Execution
- **What worked:** The r=0.08 correlation between baseline grants and baseline quits (versus r=0.49 for smoking prevalence) provided clean identification for the quit rate result. The convergence test was the decisive diagnostic.
- **What didn't:** PLDR spending data (404); fingertipsR package unavailable for R 4.5 (used direct API instead); ODS file parsing was fragile for later-year grant allocations.
- **Surprise finding:** Expected "cuts cause harm" story but found the opposite direction — higher-grant LAs maintained MORE quits. The real story is "cessation capital" — durable service infrastructure that survived 4 years of budget cuts but collapsed during COVID.
- **Review feedback adopted:** Added convergence diagnostic (r=0.08 vs 0.49), baseline quits × trend control (β increases from 174 to 214), log specification (18.3%), normalized specification (11%). Fixed table formatting (coefficient/SE on separate rows). Moderated causal language throughout.
