## Discovery
- **Idea selected:** idea_0355 — prescribed fire liability reform exploits vivid paradox (tort law causes more fire) with massive public data
- **Data source:** USDA FPA FOD (1.88M records, Kaggle mirror) + `daLaw` from `erer` R package
- **Key risk:** daLaw gives current status, not reform dates — required manual legal research to code treatment timing

## Execution
- **What worked:** CS DiD with staggered adoption is a clean design; FPA FOD is excellent data; the TWFE/CS divergence emerged naturally as a compelling methodological finding
- **What didn't:** Direct USDA download blocked (403) — Kaggle mirror gave 5th edition (2015 cutoff) instead of 6th (2020); debris burning proxy for prescribed fire is noisy
- **Review feedback adopted:** Added explicit proxy caveats, expanded lightning placebo discussion, added power/MDE paragraph, clarified treatment of "uncertain" states
