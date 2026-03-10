# Revision Plan (Stage C)

## Key Reviewer Concerns and Responses

### 1. Mean Reversion (GPT1, GPT2 — Must Fix)
Running variable (2008-2010 GDP) overlaps with pre-period (2007-2013 avg).
**Fix:** Add specification using post-2014 GDP levels as outcome with RV as control. Also show pre-2008 placebo.

### 2. No Formal First Stage (All three — Must Fix)
**Fix:** Estimate RDD on ERDF payment change at the cutoff using existing data.

### 3. EU-Only Sample (GPT1, GPT2 — Must Fix)
**Fix:** Re-run main RDD excluding candidate/EFTA countries. Make this the main specification.

### 4. Estimand Language (GPT1, GPT2)
**Fix:** Further calibrate language from "withdrawal" to "threshold classification effects." Already partially done.

### 5. Event Study Not True RD (GPT1, GPT2)
**Fix:** Relabel as descriptive complement. Add running variable controls.

### 6. Donut Fragility (All three)
**Fix:** Add region-level leave-one-out within bandwidth. Acknowledge fragility more directly.

## Execution Order
1. New R analysis: EU-only RDD + first stage + non-overlapping outcome
2. Update paper.tex with new results and calibrated language
3. Recompile and verify
