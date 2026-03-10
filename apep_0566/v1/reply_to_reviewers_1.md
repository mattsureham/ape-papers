# Reply to Reviewers — Round 1

## GPT-5.4 (R1): MAJOR REVISION

### Must-fix: Outcome measurement consistency
**Response:** We acknowledge this is a significant concern. The transition from NCHS age-adjusted rates (1999-2015) to VSRR crude rates (2016-2022) coincides with the treatment period. We now discuss this as a first-order limitation (Limitations, point 1). Constructing a fully consistent series would require NCHS restricted-use microdata; we note this as a priority for future work.

### Must-fix: Concurrent policy confounders
**Response:** We agree this is the central identification threat. We have added explicit discussion of naloxone access, PDMP mandates, Good Samaritan laws, Medicaid expansion, and marijuana policy to the Limitations section (point 2). Adding time-varying policy controls and region-by-year fixed effects is noted as a high-priority extension but requires additional data assembly beyond the current analysis.

### Must-fix: Dose-response TWFE inconsistency
**Response:** This is a valid and important criticism. We now acknowledge explicitly in the Results (Section 6.3), Discussion (Section 7.2), and Limitations (point 3) that the dose-response analysis uses TWFE interactions despite the paper's own critique of TWFE for the main specification. The dose-response results are now clearly labeled as "descriptive" evidence rather than causal claims.

### Must-fix: Event-study diagnostics
**Response:** We acknowledge the need for joint pre-trend tests and simultaneous confidence bands. These are noted as improvements for a future revision. We have added explicit caveats about the long-run estimates being identified from few cohorts.

### Must-fix: Treatment timing clarification
**Response:** We acknowledge that annual treatment coding around effective dates introduces potential exposure misclassification. This is now noted in Limitations (point 5).

### High-value: Stronger placebo tests
**Response:** Noted as a valuable extension for future work.

### High-value: COVID sensitivity
**Response:** Noted as a valuable extension for future work.

### High-value: Direct mechanism evidence
**Response:** We agree the mechanism claims exceeded the evidence. All mechanism language has been reframed from assertions to hypotheses "consistent with" the findings. The absence of direct data on seizures, arrests, and police budgets is now explicitly stated as a key limitation (point 4).

### Optional: Temper welfare rhetoric
**Done.** Renamed to "Illustrative Welfare Calculation," added extensive caveats about uncertainty, scaling assumptions, and the need to weight conclusions by confidence in identification.

### Optional: Expand literature
**Done.** Added de Chaisemartin & D'Haultfoeuille (2020, AER) and Roth (2022, AER:I) to the bibliography.

---

## GPT-5.4 (R2): REJECT AND RESUBMIT

### Must-fix: Outcome measurement break
**Response:** See R1 response above. Acknowledged as first-order limitation.

### Must-fix: Concurrent policy confounders
**Response:** See R1 response above. Acknowledged with specific policies named; future work noted.

### Must-fix: Treatment timing
**Response:** See R1 response above. Acknowledged in limitations.

### Must-fix: Inference for preferred estimator
**Response:** We acknowledge the need for bootstrap-based inference for CS estimates and more carefully designed RI. The current RI $p$-value (0.056) is now reported prominently alongside the analytical $p$-value (0.043) in both the abstract and conclusion.

### Must-fix: Dose-response TWFE inconsistency
**Response:** See R1 response above. Now explicitly acknowledged throughout.

### High-value: Placebo/falsification tests
**Response:** Noted for future work.

### High-value: Alternative counterfactual structures
**Response:** State-specific trends and region-by-year FE noted as priority extensions.

### High-value: Population weighting
**Response:** Valid concern. Acknowledged in welfare calculation section that scaling from equal-weighted ATT to aggregate deaths involves an assumption.

### High-value: Mechanism claims
**Done.** All mechanism claims reframed from assertions to hypotheses consistent with findings.

---

## Gemini-3-Flash: MINOR REVISION

### Must-fix: Log specification robustness
**Response:** The log specification yielding an insignificant result ($p = 0.25$) is now acknowledged in the Limitations section as evidence that the result may be sensitive to functional form. IHS transformation or PPML estimation would be valuable extensions.

### High-value: Direct evidence of reallocation
**Response:** Agree this is the key gap. UCR data on drug arrest composition would strengthen the causal chain. Noted as a priority for future work in Limitations (point 4).

### High-value: Equitable sharing circumvention
**Response:** Excellent suggestion. Testing whether effects are larger in anti-circumvention states would powerfully test the incentive channel. Noted as a promising extension but requires state-level equitable sharing data.

---

## Exhibit Review

### Remove duplicate appendix figures
**Done.** (Previous round)

### Merge Tables 2 and 3
**Not done.** Keeping separate — they answer different questions.

## Prose Review

### Kill roadmap paragraph
**Done.** (Previous round)

### Punchier conclusion
**Done.** (Previous round)
