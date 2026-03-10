# Internal Review (Claude Code) - Round 1

**Reviewer:** Claude Code (internal)
**Paper:** Walls Without Bricks: Do Temporary Schengen Border Controls Reduce Regional Economic Activity?
**Date:** 2026-03-10

## PART 1: CRITICAL REVIEW

### 1. Identification and Empirical Design

The staggered DiD design exploiting variation across six border segments is well-suited to the research question. The paper correctly identifies that naive TWFE conflates national trends with border-specific effects and demonstrates this convincingly with the country-by-year FE specification.

Key concern: Treatment timing is coded as 2015 for controls beginning in Sep/Nov 2015, meaning the first "treated" year contains only 3-4 months of exposure. The paper now acknowledges this (Section 3.3) and directs readers to interpret event time +1 and beyond for the clearest signal.

The parallel trends assumption is tested extensively: CS pre-test (p=0.9999), visual event studies, HonestDiD sensitivity analysis. The significant long-lead coefficients in the CS event study are plausibly attributed to Eastern European catch-up growth and do not invalidate the design.

### 2. Inference and Statistical Validity

Standard errors are clustered at the NUTS3 level throughout. Randomization inference (1,000 permutations) yields p=0.002 for the naive TWFE, confirming statistical significance even with few treatment clusters. Sample sizes are reported consistently across specifications. The CS aggregate ATT of -0.007 (SE=0.005, p=0.112) is correctly characterized as insignificant.

### 3. Robustness

Extensive: country-by-year FE, alternative control groups, pre-COVID truncation, leave-one-segment-out, placebo timing, RI, HonestDiD. The placebo failures are correctly interpreted as evidence of differential national trends rather than design failure.

### 4. Contribution

Clear contribution: first quasi-experimental evidence on Schengen border control effects using sub-national data. Well-positioned against the simulation literature (EP 2016, Aussilloux 2016).

### 5. Results Interpretation

Appropriately calibrated. The null is presented honestly without over-claiming. The sectoral result (trade/transport -8.4%) is appropriately caveated given the smaller sample.

## PART 2: CONSTRUCTIVE SUGGESTIONS

1. A map showing treated/control/interior NUTS3 regions would greatly improve reader comprehension.
2. The SA event study could move to the appendix to streamline the main text.
3. Consider discussing whether the null result is driven by low statistical power vs. genuinely small effects.

## DECISION

DECISION: MINOR REVISION
