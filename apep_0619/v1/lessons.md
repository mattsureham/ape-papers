## Discovery
- **Idea selected:** idea_0586 — H-1B lottery as true randomization for firm R&D investment
- **Data source:** Bloomberg FOIA H-1B lottery data (GitHub) + SEC EDGAR XBRL API — SEC API rate-limited at 8 req/sec, full fetch takes ~20 minutes
- **Key risk:** Binomial variance of win rate creates mechanical size-variance correlation; must control carefully and demonstrate balance on primary outcome

## Execution
- **What worked:** EIN matching between H-1B employer data and SEC filings yielded 848 firms, 497 with R&D — novel linkage not previously done. Pre-lottery R&D placebo passed cleanly (p=0.95).
- **What didn't:** FY2022 data had different status codes ("ELIGIBLE" vs "CREATED") — required a debugging pass. Pre-lottery revenue fails balance test (p<0.001), creating a permanent size-variance confound for scale-dependent outcomes.
- **Review feedback adopted:** Added registration-weighted regression (β=2.90, SE=1.51, p=0.055), stratified estimation by registration bins (null in all strata), MDE/power discussion, clarified framing as test of firm substitution capacity rather than pure immigration effect, and strengthened discussion of spurious revenue pre-trend.
- **Key lesson:** For lottery-based designs with varying treatment precision, weighting by precision (inverse binomial variance) is essential robustness. Three reviewers independently flagged this — it should be standard in future lottery papers.
