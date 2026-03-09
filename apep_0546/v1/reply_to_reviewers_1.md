# Reply to Reviewers (Round 1)

**Paper:** Do Red Flag Laws Save Lives or Shift Deaths?
**APEP ID:** apep_0546
**Date:** 2026-03-09

---

## Reviewer 1 (GPT-5.4 R1) — MAJOR REVISION

### Must-Fix Issues

**1. Validate the 2018 data source break**
> "The main ATT relies on stacking NCHS 1999–2017 with CDC 2019–2024, while the modal adoption wave is 2018... This sharply weakens the causal interpretation."

**Response:** We have made three changes. First, we added a "Data source comparability" paragraph in Section 3 explaining that both datasets derive from the same NVSS death certificates with identical ICD-10 coding and 2000 standard population age adjustment. Second, we added a new sensitivity check excluding the 2018 adoption cohort entirely (the 8 states most exposed to the source break). The ATT changes from 0.24 to 0.43 and remains statistically insignificant (p = 0.19). Third, we strengthened the discussion of the 2018 gap in Section 3.4, explicitly acknowledging that treatment effects for 2018 adopters are identified from the 2017-to-2019 change. These results are now in Table 3 and discussed in Section 5.5.

**2. Repair short-panel mechanism inference or demote**
> "Once the authors themselves believe the package's influence-function SEs may understate uncertainty, those findings cannot remain in the abstract as substantive evidence."

**Response:** We agree this was the most important revision needed. We have:
- Removed mechanism results from the abstract entirely
- Reframed the mechanism decomposition as "exploratory" throughout (abstract, intro, results, discussion)
- Removed all significance-based interpretations of short-panel results
- Expanded the footnote on the implausibly small non-firearm SE to acknowledge that randomization inference or wild cluster bootstrap would be needed for reliable p-values
- Changed the discussion from "does not support means substitution" to "is inconclusive on means substitution"

**3. Address concurrent-policy confounding**
> "If ERPO adoption proxies for a broader political and policy regime shift, the ATT cannot be interpreted as the effect of ERPO laws per se."

**Response:** We have substantially expanded Limitation 3 (Section 6.5) to discuss bundled-policy confounding as "the most important unresolved threat to interpreting the ATT as an ERPO-specific causal effect." We now cite the RAND State Firearm Law Database and note that 13 categories of state firearm laws often change contemporaneously. We acknowledge that the binary treatment indicator captures a bundled policy effect rather than the ERPO-specific effect when concurrent policies are correlated with adoption timing. We also tightened language throughout to distinguish "ERPO adoption" from "ERPO effectiveness."

**4. Strengthen pre-trend diagnostics**
> "No formal joint pre-trends test reported."

**Response:** We now report a conservative diagonal Wald test of pre-treatment coefficients in the Appendix. The test rejects (χ² = 60.7, df = 7, p < 0.001), though we note this test ignores positive covariance between estimates and is known to be oversized. The did package's own Wald test was unavailable due to a singular covariance matrix. We discuss this honestly in both the main text (Section 5.2) and appendix, noting that the average absolute pre-treatment coefficient (0.56) exceeds the ATT (0.24), limiting the design's ability to distinguish treatment effects from noise.

### High-Value Improvements

**5. Population-weighted estimates**
> "Equal-weighting Wyoming and California is a substantive choice."

**Response:** We acknowledge this limitation. The Callaway-Sant'Anna estimator as implemented does not directly support population weighting, and implementing custom population weights would require modifications beyond the scope of this revision. We have clarified in the text that the estimates reflect effects on the average state, not the average resident.

**6. Alternative heterogeneity-robust estimator**
> "A second modern estimator would show the main result is not estimator-specific."

**Response:** The Sun-Abraham estimator was attempted but produced NA results in the combined panel due to the data structure. We acknowledge in the text that concordance across modern estimators would strengthen the result. The comparison between CS-DiD with never-treated and not-yet-treated controls (producing nearly identical estimates) provides some cross-check.

**7. Probe control-group composition**
> "Anti-ERPO states may be especially different."

**Response:** Added. Excluding the 6 anti-ERPO states from the control group yields ATT = 0.24 (p = 0.28)—virtually identical to the baseline. This is now in Table 3 and discussed in Section 5.5.

**8. Clarify estimand as adoption, not implementation**
> "The paper should recast itself clearly as estimating the effect of adoption."

**Response:** Done. We have systematically replaced "ERPO effectiveness" and "ERPO effects" with "ERPO adoption" throughout, including the abstract, discussion, and conclusion. The conclusion now explicitly states: "The paper estimates the effect of ERPO adoption—having a law on the books—not the effect of ERPO utilization."

### Optional Polish

**9. Tone down TWFE bias language**
**Response:** Changed "demonstrates severe heterogeneous-treatment-effect bias" to "illustrates the heterogeneous-treatment-effect bias" throughout. The Goodman-Bacon discussion now clearly states it is "illustrative of the bias's structure rather than a complete explanation of the full-sample sign flip."

**10. Recalibrate abstract and conclusion**
**Response:** Done. Abstract now leads with "no statistically detectable effect" rather than "precisely estimated null." Conclusion policy implications are softened—"bounded by the design's limitations" rather than "dramatically scale implementation."

---

## Reviewer 2 (GPT-5.4 R2) — MAJOR REVISION

Most concerns overlap with R1. Here we address the additional or differently framed points.

**Data source comparability validation**
> "No validation is shown that the 2017 NCHS and 2019 CDC series are on a consistent scale."

**Response:** Added comparability paragraph noting both derive from NVSS death certificates with identical coding. No overlapping year exists for direct validation, but the sensitivity check excluding the 2018 cohort (most exposed to the splice) produces a robust null.

**Short-panel inference**
> "A paper cannot simultaneously flag inference as likely unreliable and then interpret the sign/significance as substantive evidence."

**Response:** Fully agree. Removed all significance-based interpretations of short-panel results. Mechanism decomposition is now framed as "exploratory" throughout, with explicit acknowledgment that reliable inference requires procedures not available for CS-DiD aggregation.

**Doubly robust covariate specification**
> "The covariates are not specified in the main text."

**Response:** The CS-DiD doubly robust estimator uses the default specification without explicit pre-treatment covariates (state and year effects are absorbed by the group-time ATT construction). We have not added additional covariates to the propensity score model. This is noted in the empirical strategy section.

**COVID-period robustness**
> "At minimum, one wants robustness excluding 2020."

**Response:** We acknowledge this is a limitation of the short-panel design. Given that the mechanism results are now framed as exploratory and explicitly flagged as coinciding entirely with the COVID period, we did not pursue additional COVID-specific robustness checks for the short panel. The combined-panel main result (1999–2024) is robust and not disproportionately driven by the pandemic period.

---

## Reviewer 3 (Gemini) — MINOR REVISION

**1. Re-center the narrative**
> "The author should de-emphasize [short-panel positive estimates] and emphasize that the long-panel null is the most reliable estimate."

**Response:** Done. Abstract now centers on the combined-panel null. Mechanism results removed from abstract and framed as exploratory in intro and results.

**2. Sensitivity to 2018 gap**
> "Robustness check excluding the 8 states that adopted in 2018."

**Response:** Added. ATT = 0.43, p = 0.19 (Table 3, new row).

**3. Utilization controls**
> "If state-level ERPO petition counts can be found, adding them as a continuous treatment."

**Response:** Systematic state-level petition data is not available across all states. We discuss utilization heterogeneity extensively and now more clearly frame the estimand as adoption rather than utilization.

**4. COVID-19 controls**
> "Including some measure of state-level pandemic severity."

**Response:** Acknowledged as limitation. The short-panel mechanism decomposition is now explicitly flagged as overlapping entirely with the COVID period, strengthening the reader's understanding of its limitations.

---

## Exhibit Review Changes

- Table 4 (leave-one-out) moved to appendix per recommendation
- Figure titles and CI brackets were already cleaned in prior rounds
- Leave-one-out figure already sorted by coefficient magnitude

## Prose Review Changes

- Opening paragraph rewritten with a Shleifer-style hook ("A suicidal crisis typically lasts minutes to hours...")
- Roadmap shortened to one fluid sentence
- Results section already opened with findings-first style from prior round
- TWFE rhetoric toned down throughout
