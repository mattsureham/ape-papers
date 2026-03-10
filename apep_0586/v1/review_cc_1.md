# Internal Review — Round 1

**Paper:** The Hidden Pre-Trend: What a Third Census Decade Reveals About WWII Returns to Military Service
**Verdict:** Minor Revision

## Strengths

1. **Novel contribution:** The 1930 pre-baseline is a genuine methodological innovation for WWII returns literature. The three-decade panel enables a pre-trend test impossible with standard two-decade designs.
2. **Scale:** 9.1 million draft-age men is orders of magnitude larger than any previous individual-level study of WWII returns.
3. **Honest results:** The paper confronts the failed pre-trend test head-on rather than hiding it, making the pre-trend itself the main finding.
4. **Clean identification narrative:** The state × cohort reduced-form design is clearly explained, with the Tydings Amendment providing institutional motivation.
5. **Strong robustness:** LOO (stable range -0.27 to -0.23), RI (p < 0.001), alternative cohort definitions all consistent.

## Weaknesses

1. **Instrument exclusion restriction:** Agricultural share predicts mobilization but also correlates with state-level economic structure. The paper acknowledges this but could discuss more formally whether the pre-trend reflects an exclusion restriction violation vs. a parallel trends failure.
2. **30% random sample:** Memory constraints required subsampling for regressions. While 2.7M observations is sufficient, this should be noted as a limitation and verified that results are stable across samples.
3. **Limited wage analysis:** Log wage results are noisy (only available for subset with positive earnings in both periods). This weakens the multi-outcome story.
4. **Age placebo specification:** The placebo uses birth_year FE only (no state FE) because mob_exposure is state-level and absorbed. This is a weaker test than the main specification.

## Minor Issues

- Page 27 had large blank space (now fixed with contributor placeholder correction)
- BibTeX warnings for missing journal fields on 7 entries (books/reports — acceptable)

## Recommendation

The paper makes a compelling methodological point with massive data. The pre-trend finding is the genuine contribution. Proceed to external review.
