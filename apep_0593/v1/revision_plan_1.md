# Revision Plan 1 — APEP-0593

## Summary of Reviewer Feedback

- **GPT R1**: MAJOR REVISION — treatment dilution, wild cluster bootstrap, domestic placebo under cty×yr FE
- **GPT R2**: MAJOR REVISION — outcome-treatment mismatch, recalibrate claims, WCB, exclude 2017, fix SE text inconsistency, common sample, weighted regressions
- **Gemini**: MINOR REVISION — day-trip calibration, WCB, regional GDP controls
- **Exhibit review**: Promote heterogeneity table, consolidate figures
- **Prose review**: Top-journal ready; minor sharpening suggestions

## Revision Workstreams

### W1: Recalibrate Claims (MUST-FIX)
All three reviewers note the title/abstract/conclusion overstate what the design identifies. The paper studies *aggregate foreign accommodation nights* in border vs interior regions — not "cross-border tourism" specifically.

- **Title**: Keep catchy title but add subtitle clarification
- **Abstract**: Replace "cross-border tourism" with "foreign tourist accommodation nights" where causal claims are made
- **Introduction**: Acknowledge that "foreign nights" includes non-EU travelers; frame as an attenuated proxy
- **Conclusion**: Narrow claims to "foreign accommodation nights" rather than "cross-border mobility"

### W2: Wild Cluster Bootstrap (MUST-FIX)
27 country clusters → asymptotic inference may be unreliable. All three reviewers request WCB.

- Add `fwildclusterboot` to 04_robustness.R
- Report WCB p-values for main specs (Table 2 Cols 1, 3) and placebo
- Report in robustness section of paper.tex

### W3: Exclude 2017 Robustness (MUST-FIX)
2017 is a half-treated year (RLAH took effect June 15). Add spec with Post = {2018, 2019} only.

- Add to 04_robustness.R
- Report inline in robustness section

### W4: Fix SE Text Inconsistency (MUST-FIX)
Paper says "standard errors are larger" under country×year FE, but Table shows SE drops from 0.109 to 0.016. Fix the text.

### W5: Common-Sample Comparison (HIGH-VALUE)
Re-estimate Column 1 on the same 1,661 obs used by Column 3 (after singleton removal).

- Add to 03_main_analysis.R
- Add column to Table 2

### W6: Population-Weighted Specification (HIGH-VALUE)
Add weighted regression using pre-treatment population.

- Add to 04_robustness.R
- Report inline in robustness section

### W7: Reframe Mechanisms (HIGH-VALUE)
Recast Section 6 as "Interpretations Consistent with the Null" rather than definitive causal mechanisms.

### W8: Prose Polish
- Implement selected suggestions from prose review (final sentence, data narrative)
- Acknowledge day-trip measurement limitation more prominently
