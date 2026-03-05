# Revision Plan - apep_0529 v1

## External Review Summary
All three referees (GPT-5.2, Grok-4.1-Fast, Gemini-3-Flash): MAJOR REVISION

## Core Issues (Consensus)

### 1. Parallel Trends Violation (All reviewers)
The CS pre-test rejects parallel trends (p = 3e-5). Current approach: honest acknowledgment + CS-DiD as preferred estimator. Reviewers want either:
- Rambachan-Roth honest DiD bounds (HonestDiD package)
- Reframe entirely as descriptive
- Alternative identification (border discontinuity, synthetic control)

### 2. Treatment Heterogeneity: Binding vs Vigilance (GPT, Grok)
Binary treatment conflates binding ZFEs (Paris, Lyon) with vigilance-only zones. Need to code enforcement regime and test dose-response.

### 3. Residential Sorting (Gemini, GPT)
The 5.3pp RN decline could reflect composition changes (green professionals moving in, car-dependent households moving out). Need census data to test.

### 4. Low Power / MDE (Grok, GPT)
Report minimum detectable effect for ENP given SE=0.141. The null is imprecise, not informative.

## Actions for v2 Revision
1. Add HonestDiD bounds (Rambachan-Roth 2023) for sensitivity to pre-trend violations
2. Code binding vs vigilance enforcement status; re-estimate with binding-only treated
3. Add pre-treatment balance table (demographics, income, density)
4. Report MDE calculations
5. Add placebo outcomes (incumbent party share)
6. Investigate residential sorting with census data if available
