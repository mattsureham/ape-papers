# Reply to Reviewers — apep_0590 v1

## Response to GPT-5.4 R1 (Reject and Resubmit)

### 1. Identification failure
**Reviewer concern:** The causal design fails and the paper should not support its policy-oriented title.
**Response:** We agree. We have rewritten Section 5.1 to present the design as exploratory from the outset, removing claims that the rollout supports parallel trends. The identification and its failure are now framed honestly throughout.

### 2. Inference level mismatch
**Reviewer concern:** CS-DiD bootstrap may not account for state-level treatment assignment.
**Response:** We have added an explicit discussion of this concern in Section 5.2. We note that the default multiplier bootstrap resamples at the municipality level. We argue that this concern *strengthens* our main conclusion: if standard errors are understated, the parallel trends violations are even more severe. State-level clustering for CS-DiD is deferred to a future version with re-estimated models.

### 3. Treatment too coarse
**Reviewer concern:** State-level treatment when actual eligibility is municipality-level.
**Response:** We have added a "Treatment measurement" paragraph to Section 5.5 (Threats to Validity) explicitly discussing the ITT interpretation, attenuation, and the disconnect from the plot-level mechanism.

### 4. Additional estimators (Sun-Abraham, Borusyak et al.)
**Response:** Citations added to Section 5.3. Implementation deferred to future version.

### 5. Reframing
**Response:** Title already centers on "Estimator Choice and Identification Failure." Section 5.1 now presents design as exploratory from the start.

---

## Response to GPT-5.4 R2 (Reject and Resubmit)

### 1-4. Same core issues as R1
**Response:** See above.

### 5. Overlap diagnostics
**Response:** Existing text in Section 4.6 (Geographic Distribution) documents the imbalance quantitatively (13 high-forest controls, 186 total controls). Figure 1 (now in main text) shows the geographic pattern visually.

### 6. Border design / matching
**Response:** Excellent suggestion for future work. Noted in the conclusion as a path forward.

### 7. De-emphasize sparse subgroup estimates
**Response:** The heterogeneity section already caveats that "these cannot support causal claims." We maintain them as descriptive evidence about data structure.

---

## Response to Gemini-3-Flash (Major Revision)

### 1. Bounding the violation
**Reviewer concern:** Rambachan-Roth failure should be better addressed.
**Response:** The VCV near-singularity is discussed in the Identification Appendix. We note this failure is itself informative about the severity of the pre-trend violation.

### 2. "Available land" mechanism
**Reviewer concern:** Find sub-sample where clearing-to-enroll might be visible.
**Response:** The heterogeneity analysis attempts this (high-forest subgroup), but the control group has only 13 municipalities. Municipality-level enrollment data would enable this analysis; its absence is a key limitation.

### 3. Within-state comparison
**Response:** Agreed — municipality-level beneficiary counts would transform the analysis. This is highlighted as the key path forward in the conclusion.

---

## Response to Exhibit Review (Gemini)

### Move Figure 1 (map) and Figure 3 (event study) to main text
**Done.** Both figures now appear in the main text (Sections 4 and 6 respectively).

### Move Table 4 to main text
**Not done.** The robustness table is already referenced prominently from the results section. Moving it would extend the already-long main text.

---

## Response to Prose Review (Gemini)

### Top suggestions incorporated:
1. Removed hedging language in several locations
2. Strengthened summary statistics framing
3. Active voice in data extraction section

### Not incorporated:
- Full "punchier" rewrites deferred to prose polish pass
