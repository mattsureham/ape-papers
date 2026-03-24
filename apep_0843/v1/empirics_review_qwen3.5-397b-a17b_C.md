# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant C)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** C
**Date:** 2026-03-24T14:36:18.786532

---

# Review: Notarize This: Remote Online Notarization Laws and New Business Formation

## 1. Idea Fidelity

The paper pursues the original idea with high fidelity regarding the core identification strategy and data sources. It correctly employs the Callaway-Sant'Anna staggered difference-in-differences estimator on Census Business Formation Statistics (BFS) via the FRED API, matching the manifest's specifications. The exclusion of COVID-era emergency adoptions to maintain a clean pre-pandemic window is consistent with the manifest's identification strategy. However, there is a deviation in the sample period: the manifest specified data through February 2026 (260 months), while the primary specification uses data through December 2019 (186 months), with robustness checks extending to 2024. While scientifically justified to avoid pandemic confounds, this reduces the sample size from the projected 13,260 state-months to 9,486. Additionally, the manifest proposed heterogeneity analysis by "pre-RON notarization stringency," but the paper relegates this to the discussion rather than the empirical results section. These are minor deviations but warrant acknowledgment.

## 2. Summary

This paper estimates the causal effect of Remote Online Notarization (RON) laws on new business formation across U.S. states between 2012 and 2019. Using monthly state-level data and a staggered difference-in-differences design, the author finds a precisely zero effect on business applications, including corporate filings where notarization requirements are most binding. The results suggest that while RON modernizes legal processes, in-person notarization is not a binding constraint on entrepreneurship in the United States, offering a credible null result for the e-government literature.

## 3. Essential Points

The authors must address three critical issues to ensure the econometric validity and interpretability of the results:

1.  **Outcome Measure Validity:** The primary outcome is IRS EIN applications (Census BFS). While convenient, the federal EIN Form SS-4 does not typically require notarization; notarization requirements attach to *state* corporate filings (e.g., Articles of Incorporation). Using EIN applications as a proxy for notarization friction introduces measurement error if the bottleneck is at the state filing level rather than the federal tax ID level. The authors must explicitly acknowledge this limitation or provide evidence that state filing costs correlate tightly with EIN application timing. Without this, the null could reflect a mismatch between the policy instrument (state notarization) and the outcome measure ( federal tax registration).

2.  **Exploiting Heterogeneity in Stringency:** The manifest proposed heterogeneity analysis by "pre-RON notarization stringency." The paper currently treats RON adoption as a binary uniform shock. However, states vary significantly in how often notarization is required for business formation (e.g., some states require it for all corporate documents, others only for specific affidavits). Pooling all treated states assumes homogeneous treatment intensity. The authors should interact the treatment indicator with a measure of pre-existing notarization burden (e.g., number of required notarized documents for incorporation) to test if effects are larger where the friction was initially heavier. This is crucial for ruling out the hypothesis that RON matters only in high-stringency environments.

3.  **Inference and Finite Sample Corrections:** The design relies on 51 clusters (states). While the Callaway-Sant'Anna estimator is robust to heterogeneous effects, inference with fewer than 50 clusters can sometimes be sensitive to standard asymptotic assumptions. Given the claim of a "precise zero," the authors should bolster the inference section by discussing finite sample properties. Implementing a wild bootstrap placebo test or reporting inference adjustments (e.g., WLD) would strengthen the confidence interval claims, ensuring the "null" is not an artifact of standard error underestimation in a small-cluster setting.

## 4. Suggestions

The following recommendations are intended to enhance the paper's robustness, clarity, and contribution to the literature. These suggestions focus on econometric refinement, data visualization, and narrative framing, constituting the bulk of this review.

**Deepening the Mechanism Analysis**
The paper argues that corporate
