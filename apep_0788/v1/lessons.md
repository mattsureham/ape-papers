## Discovery
- **Idea selected:** idea_0904 — CBAM trade deflection via DDD. Strong because it names a mechanism, uses a triple-diff, and speaks to one of the most active policy debates in climate economics.
- **Data source:** UN Comtrade API — worked well with primary key. India missing from API, reducing exporters from 8 to 7.
- **Key risk:** Short post-treatment window (15 months) and Russia-Ukraine war confounding pre-trends.

## Execution
- **What worked:** DDD design with covered/uncovered product comparison is very clean. PPML and OLS agree. Null result is consistent across all robustness specifications.
- **What didn't:** Pre-trends show some volatility at t=-9 and t=-6, attributed to Russia-Ukraine war differential impacts. Joint pre-trend test p=0.041 is borderline.
- **Review feedback adopted:** Explained India's absence, expanded pre-trend discussion with near-CBAM coefficients, added PPML confidence interval bounds to quantify what magnitudes are ruled out.
