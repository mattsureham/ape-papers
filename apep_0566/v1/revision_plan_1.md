# Revision Plan — Round 1

Based on tri-model referee review: GPT-5.4 R1 (MAJOR REVISION), GPT-5.4 R2 (REJECT AND RESUBMIT), Gemini (MINOR REVISION).

## Key Concerns Across All Reviewers

1. **Causal language over-claimed** — all three reviewers flag mechanism assertions exceeding the evidence
2. **Dose-response TWFE inconsistency** — paper rejects TWFE for main spec but uses it for dose-response
3. **Concurrent policy confounders** — naloxone, PDMP, Medicaid expansion not controlled for
4. **Outcome measurement break** — age-adjusted (1999-2015) vs crude (2016-2022)
5. **Welfare calculation too aggressive** — borderline RI p-value + scaling concerns

## Changes Made

### Must-Fix (addressed in revision)
1. **Calibrated causal language throughout** — abstract, introduction, results, discussion, conclusion all softened from "reform reduced" to "reform is associated with lower" and "evidence suggests"
2. **Dose-response TWFE limitation acknowledged explicitly** — added caveat paragraph in results section (6.3), discussion, and limitations noting the methodological inconsistency
3. **Welfare calculation heavily caveated** — renamed to "Illustrative Welfare Calculation," added uncertainty language, acknowledged scaling assumptions
4. **Expanded Limitations section** — six numbered limitations covering: measurement break, concurrent policies, dose-response TWFE, mechanism data gap, timing precision, long-run estimates and RI borderline
5. **Mechanism claims reframed as hypotheses** — throughout paper, mechanism language changed from assertions to "consistent with" formulations
6. **Added citations** — de Chaisemartin & D'Haultfoeuille (2020), Roth (2022) added to bibliography and cited in methodology section

### Not Addressing (justified)
- Adding concurrent policy controls: Would require new data collection and analysis; noted as limitation and direction for future work
- Reconstructing consistent outcome series: Would require access to full NCHS microdata; noted as limitation
- Replacing dose-response TWFE with multi-valued staggered estimator: Not available in standard software; acknowledged limitation
- Joint pre-trend tests / simultaneous confidence bands: Would require re-running R analysis; noted as direction for improvement
- Direct mechanism evidence (seizure revenues, arrest composition): Data not available in current pipeline; noted as key limitation
