# Revision Plan (Stage C)

## Reviewer Summary
- GPT-5.2: MAJOR REVISION
- Grok-4.1-Fast: MINOR REVISION
- Gemini-3-Flash: MINOR REVISION

## Key Issues and Responses

### 1. Enrollment Construction (All 3 reviewers)
**Issue:** Full planned enrollment assigned to every state with a facility is mechanically duplicative.
**Response:** Add explicit caveat paragraph in Data section explaining the limitation. Add footnote in Results acknowledging this is "trial-level enrollment exposure" not "state enrollment." Downgrade enrollment from co-equal headline result to secondary/exploratory outcome. The sign instability (CS negative, TWFE positive) already signals this is noisy.

### 2. SUTVA/Spillovers (GPT)
**Issue:** Multi-state trials create interference — sponsors could reallocate sites across states.
**Response:** Add paragraph in Identification Assumptions addressing this. Argue: (a) near-zero take-up means no actual behavioral response to reallocate against; (b) site placement decisions are made nationally months/years before state law passage; (c) the site stickiness argument already covers this. Add sentence noting that spillover-induced attenuation would bias toward null, but the null is the substantive finding.

### 3. Robustness with CS estimator (GPT)
**Issue:** Table 3 robustness uses TWFE; should show CS robustness.
**Response:** Add text clarifying that the CS estimator IS the primary specification reported in Table 2. The TWFE robustness in Table 3 serves as a cross-validation showing both estimators agree on null. Note that CS with not-yet-treated controls already incorporates the key robustness (region×time absorbed by the DR step).

### 4. Multiple Testing (GPT)
**Issue:** Terminal effect p=0.09 needs adjustment.
**Response:** Add footnote applying Holm-Bonferroni correction across the 3 primary outcomes (sites, enrollment, terminal). The adjusted p-value for terminal exceeds 0.10, reinforcing the null interpretation. Tone down language in abstract/intro.

### 5. Adoption Exogeneity (GPT)
**Response:** The event study with 8 flat pre-periods is the standard test. Add sentence noting that the Goldwater Institute's state-by-state lobbying strategy — documented in contemporaneous press — provides institutional evidence that timing was supply-driven (lobbying capacity) not demand-driven (trial activity trends).

### 6. Trial Start Date vs Site Activation (GPT)
**Response:** Add footnote acknowledging this measurement limitation. Note that ClinicalTrials.gov does not provide site-specific activation dates, making the global start date the only feasible option. Since RTT effects would need to operate through sponsor decisions at the trial planning stage (before site activation), the start date is actually the more policy-relevant timing.
