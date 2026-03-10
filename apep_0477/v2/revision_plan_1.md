# Revision Plan — apep_0477 v2

## Summary of Reviews

| Reviewer | Decision | Key Issues |
|----------|----------|-----------|
| GPT R1 | Reject & Resubmit | E/F manipulation, overclaiming, subsample, propagation SEs |
| GPT R2 | Major Revision | Same concerns, plus fuzzy regulatory treatment, discrete RV |
| Gemini | Minor Revision | Use full sample, explore price dynamics |

## Core Issues and Responses

### 1. E/F Manipulation — Reframe Claims (ALL reviewers)
**Action:** Restructure the narrative. C/D becomes the primary clean evidence for informational nulls. E/F is framed as descriptive/suggestive evidence—the manipulation makes it conservative but not cleanly causal. Remove strong language about "regulation doesn't move markets" and replace with conditional framing.

### 2. Full Sample Estimation (ALL reviewers)
**Action:** Cannot feasibly run rdrobust on 7.1M rows, but CAN run on local windows (±15 SAP points around each cutoff). This gives us all observations near each boundary without the full-sample overhead. Report full-sample local-window estimates alongside the 500K subsample.

### 3. Bootstrap SEs for Combined Estimands (GPT R1, R2)
**Action:** Implement cluster bootstrap for decomposition and diff-in-disc SEs. 200 bootstrap replications, resampling districts.

### 4. Narrow Claims — Abstract/Intro/Conclusion (GPT R1, R2)
**Action:** Recalibrate all summary statements. Center the C/D null as the clean evidence. Present E/F as suggestive. Drop "neither regulation nor information" framing. Emphasize that we test threshold effects, not continuous pricing.

### 5. Holm vs Romano-Wolf Naming (GPT R2)
**Action:** Rename to "Holm stepdown correction" throughout. Drop "approximation to Romano-Wolf."

### 6. Discrete Running Variable Discussion (GPT R2)
**Action:** Report number of unique score support points in each bandwidth. Add sentence to methodology noting the discrete support issue.

### 7. Continuous Score Pricing Test (GPT R2, Gemini)
**Action:** Add nonparametric score-price plot showing smooth relationship away from boundaries. This helps distinguish "no threshold effect" from "no pricing at all."

## Implementation Order

1. Code: Full-sample local-window estimation (03_main_analysis.R)
2. Code: Bootstrap SEs for combined estimands (03_main_analysis.R)
3. Code: Continuous score-price plot (05_figures.R)
4. Tables: Regenerate with full-sample results, bootstrap SEs (06_tables.R)
5. Paper.tex: Reframe claims, add full-sample results, fix terminology
6. Compile and verify
