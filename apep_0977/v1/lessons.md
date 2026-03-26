## Discovery
- **Idea selected:** idea_1842 — Korea-Japan boycott trade hysteresis. Selected for sharp event timing, accessible Comtrade data, DDD design with built-in placebos.
- **Data source:** UN Comtrade monthly bilateral trade API — fetched 13,219 obs across 97 products, 2 destinations, 72 months. API reliable with subscription key.
- **Key risk:** COVID overlapping the post-period. Addressed with COVID-exclusion robustness.

## Execution
- **What worked:** The Comtrade API worked flawlessly. Smoke test confirmed instantly (beverages -93%). DDD design is clean — industrial placebo is a precise zero. Permutation test p=0.000.
- **What didn't:** Product-level regressions initially clustered on destination with only 2 clusters, producing degenerate SEs. Fixed with HC1. The Rauch differentiation mechanism was less informative than visibility — collinearity issues with three-way FEs absorbed the variation.
- **Review feedback adopted:** (1) Fixed product-level SEs from 0.000 to realistic HC1 values. (2) Softened cosmetics "zero effect" claim — actually declined 0.52 log points, just less than visible goods. (3) Added caveat about heterogeneous recovery across products vs pooled persistence. (4) Added product name labels to Table 3.
