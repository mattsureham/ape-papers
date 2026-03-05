# Revision Plan 1 — apep_0511/v1

## Summary of Referee Feedback

All three referees (GPT-5.2, Grok-4.1-Fast, Gemini-3-Flash) recommend MAJOR REVISION. Key concerns cluster around: (1) the panel RDD specification's legitimacy as an RD estimator, (2) the disconnect between cross-sectional (insignificant) and panel (significant) results, (3) insufficient crosswalk validation, (4) the share contradiction, and (5) mechanism evidence.

## Planned Changes

### 1. Soften Claims (Must-fix)
- Rewrite abstract and introduction to foreground the cross-sectional RDD's imprecision and frame the panel as supplementary/suggestive
- Remove any language implying definitive causal proof; use "suggestive evidence" framing
- Recalibrate the headline: "novel T-MSIS decomposition reveals payer-specific patterns consistent with crowd-out" rather than "significantly lower"

### 2. Address Share Contradiction (Must-fix)
- Add explicit discussion that the share RDD (Table 2, Col 4) uses the same cross-sectional approach with identical power limitations
- Note that the share is a bounded ratio — changes in numerator and denominator can offset
- Consider: if both Medicaid drug spending AND overall drug mix shift, the share can remain stable

### 3. Add Crosswalk Validation (Must-fix)
- Add appendix table showing: match rates by DSH bin, hospital characteristics of matched vs unmatched
- Show robustness to dropping low-confidence matches (single-NPI-per-ZIP restriction)

### 4. Report Number of Clusters (Must-fix)
- Add cluster counts to all panel specification tables

### 5. Add Panel Binned Scatter (High-value)
- Create binned scatter plot of residualized Medicaid drug spending vs DSH percentage for the panel
- Shows that the -1.15 estimate isn't driven by outliers at edges

### 6. Improve Timing Discussion (Must-fix)
- Add explicit discussion of HCRIS fiscal year vs T-MSIS calendar year alignment
- Note that most hospitals have calendar or near-calendar fiscal years
- Acknowledge potential attenuation from misalignment

### 7. Carve-in/Carve-out Heterogeneity (High-value)
- Classify states as carve-in vs carve-out based on publicly available information
- Run panel specification separately by carve status
- Even imperfect classification is informative per all three reviewers

### 8. Local Randomization RD (High-value)
- Add rdrandinf results in narrow window as robustness check
- Addresses GPT's concern about small-sample properties

### 9. Strengthen Validity Section
- Add period-specific density tests
- Discuss DSH component manipulation separately

## Execution Order
1. R code changes (crosswalk validation, binned scatter, carve-in/carve-out, clusters, local randomization)
2. Rerun all R scripts
3. Extensive paper.tex revision
4. Recompile
5. Write reply_to_reviewers_1.md
