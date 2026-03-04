# Internal Review — Round 1

**Verdict: Minor Revision**

## Summary

The paper examines the causal effect of England's public health grant cuts on drug misuse mortality using a DiD framework across 160 upper-tier local authorities. The research question is important and timely. The institutional setting provides plausible quasi-experimental variation. The data pipeline is well-constructed.

## Strengths

1. **Well-motivated research question** — The connection between austerity and deaths of despair is a first-order public health question with clear policy relevance.
2. **Rich institutional detail** — The background section effectively explains the grant devolution, allocation formula, and ring-fence mechanisms.
3. **Honest treatment of null results** — The paper doesn't oversell the insignificant average effect and instead presents the convergent evidence honestly.
4. **Multiple complementary specifications** — Continuous treatment, event study, tercile DiD, and leave-one-out analyses provide a comprehensive picture.
5. **Placebo test passes** — Cancer mortality null is reassuring.

## Concerns

### Major

1. **Pre-trends in event study** — The pre-treatment coefficients are significantly negative for several years. While the paper discusses this, the Rambachan-Roth analysis at M=0 includes zero. The shift from negative to positive could be regression to the mean. Consider adding a more explicit discussion of why the pre-trend pattern is consistent with the causal story vs. mean reversion.

2. **Short grant data window** — Grant data from 2016-2019 (4 years) provides very limited within-LA variation for the primary specification. This is acknowledged but the power implications could be quantified more precisely (e.g., minimum detectable effect calculation).

### Minor

3. **Treatment completion sign** — The negative coefficient on treatment completion is discussed as a compositional effect, but this deserves more investigation. Could also be a data issue (completion rate denominator changes when service access changes).

4. **Missing Callaway-Sant'Anna** — The initial plan mentioned CS-DiD but it was not implemented. Should acknowledge this decision in the methods section.

5. **Tercile results are confusing** — The tercile DiD results have the wrong sign and are discussed only briefly. Either expand the discussion or move to appendix.

## Recommendations

- Add MDE calculation to the empirical strategy section
- Expand discussion of pre-trend interpretation
- Move tercile DiD to appendix (it adds noise, not signal)
- Acknowledge the decision not to implement CS-DiD
