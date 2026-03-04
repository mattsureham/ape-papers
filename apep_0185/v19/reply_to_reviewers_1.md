# Reply to Reviewers — v19

## Response to GPT-5.2 (Major Revision)

**Re: SSIV inference (AKM/BHJ).** We acknowledge the suggestion to implement shock-level variance estimators. The current state-clustered SEs (51 clusters) are conservative for our setting with ~26 effective shocks. Future revisions may implement BHJ SSIV inference explicitly.

**Re: Origin-state policy bundles.** This is a valid concern. Our null placebo results (GDP, employment through identical network weights) and distance monotonicity address the broadest confounders. Origin-state-specific policy controls (EITC, Medicaid) are a high-value extension for future work.

**Re: In-state share endogeneity.** State×time FE absorb the state-level MW; the within-state variation in in-state share is small conditional on county FE. We note this for future robustness.

**Re: Dynamic timing evidence.** The event study was removed in this revision because it was a DiD diagnostic inappropriate for a shift-share design with continuous shocks and no single treatment date. The shift-share diagnostics (HHI, LOSO, distance monotonicity, placebos, AR sets) are the correct validity tests for this design.

## Response to Grok-4.1-Fast (Minor Revision)

**Re: SCI 2018 vintage.** Addressed in Section 6.4 and 11.5 with four mitigating pieces of evidence. Historical migration proxy is a valuable extension.

**Re: Pre-trends formalization.** Balance improves with distance-restricted instruments. Rambachan-Roth analysis in appendix.

## Response to Gemini-3-Flash (Minor Revision)

**Re: Sample size discrepancy.** Explained in Table A.1 footnote (winsorization vs. pre-winsorized sample).

**Re: Employment/job creation divergence.** Addressed in Section 9.1 with reconciliation paragraph.
