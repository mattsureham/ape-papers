# Internal Review — Round 1

**Paper:** Does Geographic Targeting of Housing Subsidies Affect Prices? Evidence from France's PTZ Reform
**Reviewer:** Claude Code (Reviewer 2 + Editor)
**Verdict:** Minor Revision

## Summary

This paper exploits the 2018 withdrawal of PTZ and Pinel housing subsidies from B2/C communes in France to estimate the capitalization of buyer-side subsidies into housing prices. Using a DiD design comparing ~26,000 treated B2/C communes to ~2,200 B1 control communes over 2014-2024, the paper finds a 2.4% decline in apartment prices, concentrated in existing housing rather than new-build. The identification is clean (single treatment date, flat pre-trends), the institutional setting is well-described, and the mechanism analysis (new-build vs existing) is genuinely informative.

## Strengths

1. **Clean identification.** Single treatment date (2018) across thousands of communes eliminates staggered-adoption concerns. Pre-trends are flat and jointly insignificant. The border sample provides a useful tighter comparison.

2. **Informative mechanism decomposition.** The finding that price effects concentrate in existing housing rather than directly-subsidized new-build is a genuine insight about subsidy incidence channels.

3. **Well-situated in literature.** Clear contributions relative to Fack (2006), Laferrère & Le Blanc (2004), and Bono & Trannoy (2023). The comparison of buyer-side vs rental subsidy capitalization is conceptually valuable.

4. **Comprehensive robustness.** Seven specifications in Table 3 provide thorough sensitivity analysis.

## Weaknesses and Recommendations

### Methodology

1. **Commune-year aggregation loses information.** The paper uses median commune-year prices rather than transaction-level data. This is understandable for the CDC aggregate period (2014-2020), but for 2021-2024 the raw DVF files are available. Consider whether a transaction-level specification for the recent period would improve precision.

2. **Control group asymmetry.** 26,000 treated vs 2,200 control communes is a large imbalance. While commune FE handle level differences, it would be useful to discuss whether weighting by transaction volume or population affects results.

3. **Limited heterogeneity analysis.** The B2 vs C decomposition is discussed qualitatively but not formally tested. A triple-diff (B2 vs C vs B1) would be informative.

### Writing

4. **Abstract is strong** — fits on page 1 with all front matter, key numbers included.

5. **Welfare discussion could be tighter.** The distributional consequences subsection adds value but the gilets jaunes reference at the end is speculative. The paper should be careful about causal claims regarding political movements.

### Exhibits

6. **Table 2 and Table 3 are clean and readable** after the booktabs conversion.

7. **Event study figures are well-formatted** with clear confidence intervals and reference period marking.

## Minor Issues

- The CONTRIBUTOR_GITHUB placeholder needs to be filled at publish time.
- The 1.6pt overfull hbox at line 175-176 is negligible.

## Decision: Minor Revision

The paper is solid and nearly ready for external review. Address the gilets jaunes speculation concern and consider the weighting discussion. The core results and identification are sound.
