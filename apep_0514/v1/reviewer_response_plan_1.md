# Reviewer Response Plan (Stage C)

## Grouped Concerns

### 1. Unit of Analysis: "Home Commune" Dilution (All 3 reviewers)
All reviewers flag that constituency-level aggregation may mask effects concentrated in the cumulard deputy-mayor's own commune. This is the strongest criticism.

**Action:** Cannot implement full "home commune" analysis in this revision (would require identifying each deputy-mayor's specific commune from Wikidata, matching to fiscal data, and constructing appropriate counterfactuals — a major data extension). Instead:
- Acknowledge this limitation explicitly in Section 4.3 (Threats) and Section 8 (Conclusion)
- Tone down claims from "no pork-barrel" to "no detectable constituency-level fiscal effects"
- Frame as the most important avenue for future research

### 2. Joint F-test on Pre-Trends (Grok)
Standard DiD validation, easy to add.

**Action:** Add joint F-test p-values for pre-treatment coefficients to event-study description. Implement in 03_main_analysis.R.

### 3. Sensitivity Dropping 2020/COVID Year (GPT, Grok)
2020 is potentially confounded by COVID-19 heterogeneous impacts.

**Action:** Add robustness check using 2023-only as post-treatment. Implement in 04_robustness.R.

### 4. Claims Calibration / Debt Marginal Significance (GPT)
"Not a single fiscal outcome exhibits a significant response" is not strictly accurate when debt is p=0.09. Claims are too strong for the estimand.

**Action:**
- Soften the "not a single" language to acknowledge debt as marginally significant
- Add brief multiple-testing note
- Recalibrate abstract and conclusion to match estimand scope

### 5. Discretionary Grant Disaggregation (GPT, Gemini)
Total grants bundle formula-based DGF with discretionary DETR/DSIL.

**Action:** Cannot disaggregate in current data (DGFiP reports "concours de l'État" as aggregate; OFGL agrégats don't separate DETR from DGF). Acknowledge as limitation.

### 6. Prose Improvements (Prose Review)
- Improve results narration (already partially done)
- Ground magnitudes in real-world terms

### 7. Exhibit Improvements (Exhibit Review)
- Table 3 labels already cleaned
- Minor: adjustbox already added to Table 2

## Execution Order
1. Add joint F-test to 03_main_analysis.R
2. Add 2023-only robustness check to 04_robustness.R
3. Re-run analysis scripts
4. Update paper.tex: claims calibration, limitations, F-test results
5. Recompile PDF
