## Discovery
- **Idea selected:** idea_1671 — Poland's Sunday trading ban and traffic accidents. Chosen for clean within-year variation, rich micro-data (minute-level timestamps), and a compelling reversal hook.
- **Data source:** SEWIK via Zenodo (88,607 records, 2020-2023). Download smooth, data quality excellent. Weather data format had different column names than expected — needed quick fix.
- **Key risk:** Trading Sunday calendar endogenous to seasonal patterns (cluster around holidays).

## Execution
- **What worked:** The seasonal illusion is a strong narrative device. Raw correlation has wrong sign; month FEs flip it. Pedestrian mechanism (IRR=0.793) is large, clean, and mechanism-consistent. Built-up area heterogeneity confirms commercial-area channel. Excluding 2020 strengthens results.
- **What didn't:** Total-accident result is fragile to placebos (Saturday p=0.054, Friday p=0.060). Non-holiday months only: effect disappears. This limits the "4% total accident" claim. The DDD hourly displacement analysis produced collinearity issues (shop_hours absorbed by hour FEs) and small, imprecise interactions.
- **Review feedback adopted:** Added COVID robustness (excl. 2020: IRR=0.933, p=0.025), built-up area heterogeneity, non-holiday months restriction, strengthened placebo discussion with explicit non-holiday attenuation evidence. Fixed DDD table interpretation. Refocused paper narrative on pedestrian dividend as primary finding.
