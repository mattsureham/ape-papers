# Internal Review - Round 1

**Reviewer:** Claude Code (self-review)
**Date:** 2026-03-04

## PART 1: CRITICAL REVIEW

### 1. Identification and Empirical Design

The DiD design exploiting the March 2018 simultaneous designation of 222 ACV cities is credible. The simultaneous announcement creates a clean single-cohort treatment, and the paper correctly notes that the additional 22 communes added after 2018 are coded conservatively (biasing toward zero). Pre-trends are flat across four pre-treatment years with a well-powered joint F-test.

**Concern:** The 123 ACV communes with no pre-treatment data are problematic — they cannot contribute to DiD identification through commune fixed effects. The paper addresses this in a footnote explaining singleton drops, which is adequate.

**Concern:** The control group expansion from ~270 sampled communes to 713 in the final panel reflects commune code inconsistencies across API and bulk data sources. While the paper has been revised to describe harmonization procedures, the mismatch between the sampling procedure (3 per département ≈ 270) and the final count (713) warrants more transparent documentation in the replication package.

### 2. Inference and Statistical Validity

Standard errors are clustered at the commune level throughout, which is appropriate. SEs are well-sized (0.011–0.080 range). The main coefficient (0.073, SE=0.016) is precisely estimated. Transaction-level nulls are credibly powered given N>546K.

### 3. Robustness

Placebo tests at 2015 and 2016 are clean (p=0.84, p=0.88). LOO analysis shows remarkable stability (0.065–0.085). Département-by-year FE yield comparable results (0.060). The paper honestly reports the CS-DiD estimation failure.

### 4. Contribution

The compositional interpretation is the paper's most original finding — the divergence between commune-level (7.3%) and transaction-level (0.6%, insignificant) estimates is scientifically interesting. This contributes to the literature on place-based policies and capitalization.

### 5. Results Interpretation

The paper appropriately distinguishes between compositional and price effects. Policy implications are proportional to evidence strength.

## PART 2: CONSTRUCTIVE SUGGESTIONS

1. Consider a triple-difference design interacting treatment with property type to directly test the compositional channel
2. Show the share of apartments in transactions over time for treated vs. control to directly visualize the compositional shift
3. Consider synthetic control for a subset of well-matched ACV cities

## DECISION: MINOR REVISION
