## Discovery
- **Idea selected:** idea_2227 — Korea 17-month short-selling ban (symmetric natural experiment)
- **Data source:** Yahoo Finance daily OHLCV for 69 KOSPI/KOSDAQ stocks — reliable for large/mid caps, ~1K obs per stock
- **Key risk:** Volatility as proxy for short-selling demand; sample limited to 69 stocks vs 2,500 universe

## Execution
- **What worked:** Cross-sectional event study is extremely clean. Pre-ban volatility explains 49% of KOSPI ban-day CAR variation. Placebo test passes cleanly. Symmetry test (ρ = -0.28, p = 0.019) is compelling. The symmetric design (ban + lift) provides built-in replication.
- **What didn't:** Variance ratio analysis was underpowered and muddled. Azure storage connection was broken (pivoted from original idea_0188). KRX investor-type data would have enabled the quantitative welfare analysis all three reviewers wanted.
- **Review feedback adopted:** Softened welfare claims throughout (conditional language, acknowledged qualitative nature). Fixed abstract/text inconsistency (1.3pp vs 2.1pp). Added endogenous benchmark caveat. Better justified sample selection. Acknowledged limitations more honestly.
- **Key reviewer insight:** All three reviewers independently flagged the same issue — without individual-level short interest and trading data, the paper can demonstrate price patterns but not welfare transfers. This is the clear V2 improvement path.
