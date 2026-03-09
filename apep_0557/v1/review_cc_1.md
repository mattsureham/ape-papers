# Internal Review — Round 1

**Paper:** Does Foreign Aid Buffer Oil Revenue Shocks? Geocoded Evidence from Nigeria
**Date:** 2026-03-09
**Verdict:** Minor Revision

## Summary

The paper tests whether pre-existing foreign aid exposure buffers Nigerian states against oil-shock-induced conflict, using a continuous DiD design around the September 2008 oil crash. The answer is a well-documented null: aid does not buffer. The paper is 31 pages, methodologically sound, and honestly reports a null result with extensive robustness.

## Strengths

1. **Clear identification strategy.** The September 2008 oil crash is a genuinely exogenous shock. Pre-determined aid exposure (as of Dec 2007) avoids reverse causality. The continuous DiD is cleanly implemented.
2. **Comprehensive robustness.** Randomization inference (1,000 permutations), leave-one-out, Poisson PPML, placebo tests, alternative shock dates, annual aggregation — the null holds throughout.
3. **Honest engagement with Boko Haram confound.** The paper doesn't pretend this problem away. The LOO analysis and discussion section address it directly.
4. **Good event study.** Pre-trend coefficients are flat around zero, supporting parallel trends.
5. **Clean figures.** The coefficient plots, event study, and RI distribution are publication-quality.

## Weaknesses

1. **Table numbering mismatch.** The code filenames (table2, table3) don't match LaTeX numbering (Table 3, Table 4) because summary stats and state descriptives come first. Not technically wrong (cross-refs work), but could confuse replicators.
2. **Oil Price control absorbed by FE.** Column (4) adds oil_price as a control but time FE already absorb it perfectly. This column adds no information — the coefficient is identical to Column (1). Consider noting this explicitly or dropping the column.
3. **Agriculture sector coefficient suspicious.** The β=2.37 for agriculture aid is extremely large and almost certainly an artifact of Boko Haram geography. The paper discusses this but the coefficient could be more prominently flagged as unreliable.
4. **No power analysis.** With 37 clusters and a null result, a minimum detectable effect (MDE) calculation would strengthen the claim that the null is informative, not just underpowered.
5. **Wild cluster bootstrap failed.** The robustness section mentions RI but the WCB failed silently. Either fix the implementation or note the failure.

## Recommendations

- Add a brief MDE/power discussion (even back-of-envelope)
- Note that Column (4) is mechanically identical to Column (1) due to time FE
- Consider whether Oil Price column should remain or be replaced
- Minor: ensure code filenames match conceptual table ordering for replicability
