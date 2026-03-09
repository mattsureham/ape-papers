# Internal Review Round 1

**Verdict: Minor Revision**

## Strengths

1. **Compelling research design.** The symmetric on-off experiment (cap imposed 2016, repealed 2019) is rare and provides an unusually clean identification opportunity. The hysteresis finding — that damage deepens after repeal — is genuinely novel.

2. **Strong event study.** Figure 2 shows textbook-quality pre-trends (flat, near-zero for k=-6 to k=-2) with a sharp break at treatment. The post-repeal trajectory continuing downward is the paper's signature contribution.

3. **Multiple corroborating analyses.** The within-Kenya tier DiD, cross-country DiD, symmetry test, and randomization inference all tell a consistent story. The RI p-value of 0.000 is particularly important given the small sample.

4. **Excellent writing.** The introduction follows the Shleifer arc well — striking fact (76 countries), clear gap (reversibility unknown), specific findings with numbers, and four literature contributions. The conceptual framework is tight.

5. **Good robustness battery.** Pre-trends validation, alternative exposure measures, Tier 2 vs Tier 1 placebo, pre-COVID window, RI, and government securities exposure placebo.

## Issues to Address

### Methodology

1. **Cross-country event study pre-trends (Fig 7).** The pre-treatment coefficients show a noticeable dip around k=-7 to k=-5, then recover toward zero. This is not flat. The text should acknowledge this more explicitly and discuss whether the cross-country parallel trends assumption is fully credible. Currently the cross-country evidence is presented as corroborating, which is appropriate framing.

2. **Standard errors with 3 clusters.** Clustering at the tier level with only 3 tiers is problematic — even with fixest's small-sample corrections, 3 clusters cannot reliably estimate the variance-covariance matrix. The RI addresses this, but the paper should discuss this limitation more prominently. Consider wild cluster bootstrap as an additional robustness check, or at minimum note that the clustered SEs should be interpreted with caution.

3. **Compositional changes.** The decline from 22 to 16 Tier 3 banks is well-discussed, but the survivorship bias argument (surviving banks are strongest, so bias works against finding hysteresis) deserves quantification. Can you show that the Tier 3 aggregate results are robust to excluding the years when banks exited?

### Presentation

4. **Table 5 missing p-values.** Most robustness specifications show "—" for p-values. These should be reported for all specifications, not just baseline and RI.

5. **Figure 3 subtitle says "partial recovery after repeal"** but the paper's main finding is NO recovery (hysteresis). The subtitle should match the finding.

6. **Appendix F (SDE table) completeness.** Verify the standardized effect size appendix is present and properly filled in per the template requirements.

## Minor Points

- The contributor placeholders (@CONTRIBUTOR_GITHUB) will need to be resolved at publish time
- Section 5.4 "Threats to Validity" could be renamed "Identification Concerns" for a more confident tone
- The reversal ratio formula in Eq. 6 uses (β̂₂ - β̂₁)/β̂₁ but the text says "reversal ratio" — clarify this is measuring how much of the cap effect is undone by repeal

## Overall Assessment

This is a well-executed paper with a genuinely interesting finding. The hysteresis result is novel and policy-relevant. The main limitation is the small sample (42 observations, 3 clusters), but this is inherent to the data and is addressed through RI. The cross-country evidence provides useful corroboration. With minor fixes to the presentation and a brief discussion of the clustering concern, this paper is ready for external review.
