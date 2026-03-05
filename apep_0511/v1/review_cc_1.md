# Internal Review 1

## Summary
This paper studies the effect of 340B Drug Pricing Program eligibility on Medicaid drug administration using an RDD at the 11.75% DSH threshold. The main finding is a significant negative effect in the panel specification (-1.15 asinh, p=0.028), with no corresponding discontinuity in Medicare drug spending or non-drug Medicaid services.

## Strengths
1. Novel research question: decomposing 340B effects by payer using T-MSIS data
2. Clean institutional setting with sharp regulatory threshold
3. Comprehensive robustness checks (bandwidth, donut hole, placebo cutoffs, year-by-year)
4. Cross-payer comparison provides compelling evidence for the incentive mechanism

## Weaknesses
1. Limited power in cross-sectional RDD (only ~68 effective observations below threshold)
2. Reliance on panel specification for statistical significance
3. DSH percentages are relatively stable, limiting within-hospital treatment variation

## Minor Issues
- Table 1 summary stats window (±10pp) should be clearly distinguished from rdrobust optimal bandwidth
- Consider reporting confidence intervals alongside p-values for rdrobust estimates

## Assessment
The paper addresses an important policy question with appropriate methods and data. The identification strategy is credible, and the cross-payer comparison strengthens the causal interpretation. The limited cross-sectional power is a known limitation of this design given the thin left tail of the DSH distribution. The panel specification provides adequate precision.

DECISION: MINOR REVISION
