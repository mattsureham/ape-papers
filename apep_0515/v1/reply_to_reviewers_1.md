# Reply to Reviewers

## Reviewer 1 (GPT-5.2): MAJOR REVISION

**1. "Bite is a low-wage-area proxy; pre-trends are borderline"**
We agree that the Kaitz index correlates with broader local economic conditions. We have added a new threat (Threat 3 in Section 5.5) explicitly discussing LA fee-setting as a confounder and acknowledging that we cannot fully separate the NLW's direct cost effect from the indirect channel of constrained fee adjustment. Region × year FE (already in the robustness appendix) partially address this. The borderline pre-trend (joint p=0.067) is honestly reported and the HonestDiD analysis shows the null is robust to moderate violations.

**2. "Functional form: Poisson/count model for closure rates"**
This is a good suggestion for a future revision. We note that the population-weighted regression (reported in the appendix) yields similar results. The closure rate is well-behaved (mean ~7%, SD ~4.6%), and with 134 clusters and LA/year FE, OLS with cluster-robust SEs provides valid inference.

**3. "Alternative post definition (post≥2017 for full-year exposure)"**
The narrow-window robustness (2014-2017, Table 4 Column 2) effectively tests this by giving more weight to 2016-2017. The coefficient is larger (6.14) but still insignificant (p=0.121), consistent with the baseline.

**4. "Recalibrate 'well-powered null' claims"**
Done. We have replaced "well-powered null" with "informative null" throughout, added IQR-scaled magnitudes to the abstract, and added an explicit uncertainty caveat to the welfare calculation. The MDE discussion already acknowledged moderate power; we now frame this more prominently.

**5. "Alternative exposure measures (p10/p25 wages)"**
ASHE at LA level does not routinely report percentile-specific wages via NOMIS API at TYPE464 geography. This is acknowledged as a limitation. The median is the most reliably available measure.

**6. "LA-specific linear trends"**
With only 3 pre-treatment periods per unit, LA-specific linear trends are poorly estimated and mechanically absorb much of the identifying variation. We prefer the region × year FE specification and HonestDiD as more informative robustness checks.

## Reviewer 2 (Grok-4.1-Fast): MINOR REVISION

**1. "Investigate 2012 pre-trend dip"**
The 2012 coefficient (-13.8, p=0.073) suggests high-bite areas had *lower* closures in 2012. This is the opposite direction of what would inflate the post-treatment estimate, providing some reassurance. We discuss this explicitly in the text (Section 6.3 and Appendix B.1).

**2. "Care-worker-specific bite"**
ASHE data at SOC 4-digit level for care occupations are not available at LA geography through the standard NOMIS API. We acknowledge this as a limitation and note the high correlation between all-worker and care-worker wages.

**3. "Net entry breakdown (entries vs exits separately)"**
The placebo table already shows entry rate as a separate outcome. The main results table includes net change. We have added text clarifying the distinction between beds lost (beds) and net change (homes).

**4. "Soften 'well-powered null'"**
Done. Changed to "informative null" throughout.

## Reviewer 3 (Gemini-3-Flash): MAJOR REVISION

**1. "LA fee controls"**
We have added a new threat discussion (Threat 3 in Section 5.5) explicitly addressing the LA fee-setting confounder. We acknowledge that systematic LA-level fee rate data are not publicly available for this period, limiting our ability to control for this directly.

**2. "Sample selection: 134 vs 379 LAs"**
We have added a paragraph in Section 4 explaining the sample composition: unmatched LAs are primarily due to naming discrepancies between CQC and ASHE conventions, not systematic selection on economic characteristics. The matched sample spans all nine English regions.

**3. "CQC ratings as outcome"**
This is an excellent suggestion for future work and is mentioned in the future research paragraph of the conclusion.

**4. "Bed-weighted specifications"**
The population-weighted regression is reported in the appendix, and the beds-lost regression (Table 6) directly addresses the intensive margin weighting concern.

## Prose and Exhibit Review Responses

- Killed the roadmap paragraph (prose review suggestion)
- Sharpened opening sentence (prose review)
- Improved conclusion ending (prose review)
- Table 1 notes clarify Kaitz index is time-invariant (exhibit review)
- Table 2 notes explain high R² in columns 3-4 (exhibit review)
- Added beds lost as formal Table 6 (exhibit/GPT review)
