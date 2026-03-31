## Discovery
- **Idea selected:** idea_1974 — Korea's mandatory English disclosure for KOSPI firms (selected for novel setting, clean data, named mechanism)
- **Data source:** Yahoo Finance (daily OHLCV) + FinanceDataReader (firm characteristics) — both worked smoothly
- **Key risk:** Concurrent reforms (Value-Up program, registration abolition) contaminating the treatment effect

## Execution
- **What worked:** Data pipeline was clean — 276K daily obs for 295 firms. DiD estimation straightforward with fixest. Financial-sector placebo is clean (p=0.82).
- **What didn't:** Pre-trends fail in the pooled sample (F=3.08, p<0.001). The headline financial-sector result (-0.397***) is driven by only 14 treated financial firms and doesn't survive a formal interaction test (p=0.58). Treatment classification is imperfect — used asset threshold only, missing the foreign ownership ≥5% criterion.
- **Review feedback adopted:** Downshifted claims from "central finding" to "suggestive and exploratory." Added treatment classification caveat. Acknowledged the interaction test failure explicitly. Added financial-sector placebo. Strengthened limitations section. Reframed from "Korea discount" paper to "novel quasi-experimental setting" paper.
- **Lesson for future:** When the subsample driving the result has few treated units (14), always run the interaction test before framing it as the headline. Triple interactions with small treated subgroups have low power, but the honest thing is to report them.
