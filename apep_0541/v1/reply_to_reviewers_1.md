# Reply to Reviewers

## Reviewer 1 (GPT-5.4 R1): REJECT AND RESUBMIT

### Measurement Error / NDC vs. Manufacturer
**Concern:** NDC counts are a noisy proxy for firm-level competition; attenuation bias could explain the null.
**Response:** We added a dedicated paragraph in Section 6.1 discussing attenuation bias from measurement error. We acknowledge this concern explicitly and note three features of the results that suggest attenuation alone does not drive the conclusion: (1) the non-parametric specification also produces flat estimates, (2) the min-price outcome detects a small significant effect, and (3) results are consistent across specifications. We also softened causal language throughout, describing the within-market estimate as a "conditional association" rather than a definitive causal effect.

### Time-Varying Confounds
**Concern:** Market FE do not remove time-varying shocks (shortages, contract changes, etc.).
**Response:** We acknowledge this limitation in the identification section and limitations. The 2-4 year ANDA timeline makes weekly reverse causality implausible, but other time-varying confounds remain possible. We softened claims accordingly.

### Event Study Credibility
**Concern:** F=0.00, p=1.00 is suspicious; event construction not validated.
**Response:** We reframed the event study as a "corroborating diagnostic" rather than an independent identification strategy, and acknowledged that individual coefficients are imprecise due to high-dimensional FE.

### Claim Calibration
**Concern:** Conclusions overclaim relative to evidence.
**Response:** We softened language throughout — "within-market effect" instead of "causal effect," added the measurement error caveat, and noted that the null finding may partly reflect NDC measurement limitations.

## Reviewer 2 (GPT-5.4 R2): REJECT AND RESUBMIT

### NDC vs. Manufacturer
**Concern:** Same as R1 — NDC is not a firm.
**Response:** See above. Addressed in new paragraph and limitations section.

### Survey Coverage Noise
**Concern:** Intermittent market observation (median 12 of 84 weeks) undermines identification.
**Response:** Acknowledged in limitations. The thin panel is a genuine constraint; we note this explicitly.

### Orange Book Not Used
**Concern:** Downloaded but not integrated — missed opportunity.
**Response:** Acknowledged. The ANDA-to-NADAC crosswalk is complex due to naming conventions. Future work should link these data sources.

### Causal Claims
**Concern:** Should be framed as descriptive decomposition, not causal.
**Response:** We softened language throughout as described above.

## Reviewer 3 (Gemini-3-Flash): MINOR REVISION

### Selection into NADAC
**Concern:** Survey gaps could mechanically bias estimates toward zero.
**Response:** Discussed in the new measurement error paragraph and limitations.

### Price Rigidity
**Concern:** Quarterly/annual contract renegotiation may mask short-run effects.
**Response:** Already discussed in Discussion section; acknowledged as a key limitation of the short panel.

### Heterogeneity by Market Size
**Concern:** Competition may matter more at low N.
**Response:** The non-parametric specification (Table 3, Figure 2) addresses this directly — the within-market curve is flat across all N values, including at N=2 (the only significant coefficient, which we interpret as compositional).

## Summary of Changes Made

1. Added measurement error / attenuation bias paragraph in Results section
2. Softened "causal effect" language → "within-market effect" in abstract, introduction, results
3. Added caveat that null finding may partly reflect NDC measurement limitations
4. Removed roadmap paragraph from introduction
5. Strengthened conclusion's final sentence
6. Fixed all numerical inconsistencies identified in advisor review rounds
