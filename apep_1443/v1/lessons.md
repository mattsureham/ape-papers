## Discovery
- **Idea selected:** idea_2354 — Taiwan holding-period bunching, chosen for multi-notch design (cf. #1 APEP paper), confirmed data access, novel geography
- **Data source:** Taiwan Actual Price Registration (plvr.land.moi.gov.tw) — 50 quarterly ZIPs, 4.36M raw transactions, no API key needed
- **Key risk:** Address-level matching insufficient for multi-unit buildings — proved fatal for placebo

## Execution
- **What worked:** Data download was reliable and fast. Bunching estimator coded cleanly. 344K repeat-sale pairs constructed efficiently after rewriting the cleaning script (first version was too slow on 4.3M rows — lesson: always select columns upfront with `fread(select=...)`).
- **What didn't:** The fundamental identification collapsed: exempt properties show b=6.68 at 730 days, meaning the counterfactual density is NOT smooth even without tax incentives. Address-level matching of multi-unit buildings creates spurious holding-period patterns at round numbers. Without unit-level identifiers, the bunching approach can't distinguish tax-induced timing from construction-to-resale cycles.
- **Review feedback adopted:** All three reviewers converged on the placebo failure. Added: limitations section, extensive-margin volume test (26% decline), tempered all causal language, reframed as a methodological contribution about bunching estimation limits in data-constrained housing markets.

## Key Lessons
1. **Taiwan's APR data lacks unit-level identifiers** — any future paper needing property-level matching must find alternative IDs (cadastral plots, building serial numbers)
2. **Placebo tests can reveal fundamental design flaws** — run them FIRST, not last
3. **Null results with contaminated placebos are uninformative** — the paper's contribution is honest reporting, not the null itself
