## Discovery
- **Idea selected:** idea_0346 — IRS SOI income-stratified migration data + SALT cap as differential shock. Chose for first-order question (does tax flight have an income gradient?), massive data (125M returns/year), and clean triple-diff identification.
- **Data source:** IRS SOI inmigall.csv (2011-2021) — wide format with _0 through _6 column suffixes was initially confusing; agi_stub gives income bracket, _0 = total across sub-categories. All 11 years downloaded cleanly.
- **Key risk:** Non-zero placebo for low-income brackets; pre-trends in simpler event study specs.

## Execution
- **What worked:** The monotonic income gradient is clean and striking — bracket 7 ($200K+) responds 3x more than bracket 1 (Under $10K). Triple-diff with saturated FE (state×bracket, year×bracket, state×year) yields -0.0048*** (R² = 0.92). Excluding NY/NJ/CT strengthens rather than weakens the result. The outflow/inflow decomposition (70/30) is a genuinely novel finding.
- **What didn't:** Low-income placebo is positive and significant (+0.003*) — not fatal but requires honest discussion. Pre-trends in simple bracket-7 event study show pre-2018 variation, though the triple-diff with full FE absorbs this. The $200K+ bracket is coarse — ideally would have $1M+ breakout.
- **Review feedback adopted:** (1) Moderated claims — changed "reconcile" to "provide new evidence that bridges"; (2) Added candid discussion of positive placebo; (3) Emphasized pre-COVID estimate (-0.0032) as more conservative benchmark; (4) Acknowledged this measures responses to federal deductibility change, not direct state tax changes.
