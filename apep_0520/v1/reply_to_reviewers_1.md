# Reply to Reviewers — Round 1

## Summary of Changes

We thank all three reviewers for thorough and constructive feedback. We address the key consensus points below. Several suggestions (implementation timing data collection, external validation against N-SSATS, within-BH placebos) are excellent ideas for a revision but require additional data that is not available in the current T-MSIS release; we note these as important extensions.

---

## Consensus Issue 1: MCO/Managed Care Heterogeneity (All 3 reviewers)

**GPT §3.4, Grok §6.2, Gemini §6.1:** All reviewers request heterogeneity analysis by managed care penetration.

**Response:** We add a discussion of this limitation and note that state-level MCO penetration data from CMS could be used to test this mechanism. We do not have within-sample variation in MCO status that changes at waiver adoption, making it a cross-sectional moderator rather than a source of identification. We note this as a priority extension.

## Consensus Issue 2: SUD Provider Decline Decomposition (All 3 reviewers)

**GPT §3.1, Grok §6.2, Gemini §6.2:** The -24% SUD decline needs investigation — is it coding substitution?

**Response:** We add text discussing that the simultaneous BH positive / SUD negative pattern is consistent with code reclassification: providers shifting from narrow SUD H-codes (H0010-H0019) to broader behavioral health codes. We note that provider-level code portfolio analysis would require the raw NPI×code×month microdata (available in T-MSIS but computationally intensive).

## Consensus Issue 3: Implementation Lags (GPT §1.1, Grok §6.1)

**Response:** We strengthen the limitations discussion to acknowledge that approval-to-implementation lags are a first-order concern. We note that lagged treatment (+6, +12 months) would test this, and that the positive CS-DiD dynamic trajectory (growing post-treatment) is consistent with gradual implementation rather than immediate response.

## Consensus Issue 4: Power/MDE (GPT §2.2, Grok §6.2)

**Response:** We add a power discussion noting that with SE ≈ 0.14, the design can detect effects of ≈0.28 log points (32%) at 80% power. The 25% point estimate falls just below this threshold, consistent with a real but underpowered effect.

## Consensus Issue 5: Covariate Balance (Grok §6.1, GPT §1.3)

**Response:** We acknowledge this limitation. Pre-period balance on observables (opioid mortality, Medicaid expansion, baseline provider density) would strengthen the design. The doubly-robust CS-DiD partially addresses this by incorporating propensity score reweighting.

## Consensus Issue 6: Estimator Sensitivity Diagnosis (GPT §2.3)

**Response:** We add text explaining that the CS vs TWFE/stacked divergence likely reflects heterogeneous treatment effects across cohorts. The Bacon decomposition shows negative timing-comparison weights pulling TWFE toward zero. CS-DiD is our preferred estimator because it avoids these contaminated comparisons, but we honestly report all three.
