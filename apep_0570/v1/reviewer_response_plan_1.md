# Reviewer Response Plan

## Grouped Concerns

### 1. Asymmetry claim overclaiming (all 3 reviewers)
- SST reimposition coefficient 0.038 (SE 0.030) is not significant
- No formal test of symmetry (β1 = β2)
- Title "Rockets Down, Feathers Up" is too strong
- **Fix:** Add formal symmetry test, report CI for asymmetry ratio via delta method, soften language throughout to "suggestive" rather than "demonstrated"

### 2. Pre-trend failures undermine identification (all 3)
- 36-month and 12-month F-tests both reject
- Placebo tests all significant
- Short-window still has p=0.011
- **Fix:** Implement Rambachan-Roth (HonestDiD) sensitivity analysis for short-window estimate. Add references. Cannot "fix" pre-trends — acknowledge more forthrightly.

### 3. Full-sample estimate overweighted (all 3)
- 130% pass-through from contaminated full sample
- Leads abstract/intro but paper acknowledges contamination
- **Fix:** Restructure paper to lead with short-window estimate. Demote full-sample to descriptive context.

### 4. Treatment classification endogeneity concern (GPT R1, R2)
- "Validated against observed price behavior" reads as outcome-dependent coding
- **Fix:** Clarify that legal mapping is primary, price behavior is ex post diagnostic only. No reclassification was done based on outcomes.

### 5. Control group heterogeneity (GPT R1, R2)
- Zero-rated and exempt products are economically different
- Food inflation driving pre-trends
- **Fix:** Add robustness check separating zero-rated vs exempt controls.

### 6. Mechanism claims speculative (GPT R1, R2)
- Political salience/enforcement untested
- **Fix:** Explicitly label as conjectures/hypotheses.

### 7. Missing methodological references (all 3)
- Need Roth (2022), Rambachan & Roth (2023)
- **Fix:** Add to references.bib and cite in empirical strategy.

### 8. Missing inference for derived quantities (GPT R1, R2)
- Pass-through rates and asymmetry ratio need CIs
- **Fix:** Delta method or bootstrap CIs.

## Workstream Priority

1. **R code additions:** Symmetry test, delta-method CIs, separated control robustness, wild bootstrap for DDD
2. **Paper reframing:** Soften asymmetry throughout, demote full-sample, qualify mechanisms
3. **References:** Add Roth, Rambachan-Roth
4. **Prose:** Address exhibit and prose review suggestions already partially done
