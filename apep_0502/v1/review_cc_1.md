# Internal Review: Round 1

**Date:** 2026-03-04
**Verdict:** Minor Revision

## Summary

This paper studies whether NAAQS PM2.5 nonattainment designation reshapes county-level energy infrastructure using a sharp RDD. The design is clean and well-validated. The main result is a precisely estimated null — no significant effect on fossil, renewable, or total capacity at the 12 μg/m³ cutoff. The paper honestly reports and interprets this null, which is an informative contribution.

## Strengths

1. **Novel question:** First paper to examine nonattainment → energy infrastructure, filling a clear gap between the CAA manufacturing literature and energy transition literature.
2. **Clean identification:** McCrary test passes cleanly (p=0.79), all four covariate balance tests pass, placebo outcome (renewable capacity) confirms null.
3. **Honest reporting:** Null results presented transparently with appropriate discussion of power limitations and alternative interpretations.
4. **Comprehensive robustness:** Bandwidth sensitivity, polynomial order, kernel, placebo cutoffs, multi-cutoff analysis.
5. **Conceptual framework:** Simple investment model clarifies conditions for observable local effects.

## Weaknesses

1. **Cross-sectional energy outcome:** Using eGRID 2022 as a single snapshot limits the analysis to stock comparisons. Panel data from EIA-860 would strengthen considerably.
2. **Low power:** Only 2.9% of observations in nonattainment. Confidence intervals are wide (−700 to +1,165 MW for fossil capacity).
3. **Tables contain raw generated LaTeX:** The \input{} tables may have formatting issues (summary_stats.tex has nested table environments).
4. **Polynomial/kernel robustness numbers in text are approximate:** Lines "ranging from 140 to 350" and kernel estimates need verification against actual results.

## Required Changes

1. Verify polynomial and kernel sensitivity numbers cited in robustness text against actual script output
2. Ensure no nested table environments when \input{} is used within a table float

## Suggested Changes

1. Discuss what a future study with EIA-860 panel data could achieve
2. Add power calculation discussion — what MDE can the design detect?
3. Consider whether commuting zone aggregation would better capture spatial displacement
