# Revision Plan 1 -- Addressing Referee Feedback

## Overview

Three external referees (GPT-5.2, Grok-4.1-Fast, Gemini-3-Flash) reviewed the paper. Two recommended Minor Revision; one recommended Major Revision. This plan addresses the six consensus issues identified across all reviews.

## Workstream 1: MCO/Managed Care Heterogeneity (All 3 reviewers)

**Action:** Add discussion of MCO contracting frictions as a limitation and potential moderator. Note that state-level MCO penetration data could be used in a future extension but is a cross-sectional moderator, not a source of identification.

**Files changed:** paper.tex (Section 7, Limitations)

## Workstream 2: SUD Provider Decline Decomposition (All 3 reviewers)

**Action:** Expand discussion of the -24% SUD decline. Explain that the simultaneous BH positive / SUD negative pattern is consistent with code reclassification (H0010-H0019 shifting to broader BH codes). Note that provider-level code portfolio analysis would require NPI x code x month microdata.

**Files changed:** paper.tex (Section 7.1)

## Workstream 3: Implementation Lags (GPT, Grok)

**Action:** Strengthen limitations discussion acknowledging approval-to-implementation lags as a first-order concern. Note that lagged treatment specifications (+6, +12 months) would test this, and that the positive CS-DiD dynamic trajectory is consistent with gradual implementation.

**Files changed:** paper.tex (Section 7.2)

## Workstream 4: Power/MDE Discussion (GPT, Grok)

**Action:** Add power discussion noting SE ~ 0.14 implies MDE ~ 0.28 log points (32%) at 80% power. The 25% point estimate falls just below this threshold, consistent with a real but underpowered effect. Report 95% CI spanning -6% to +66%.

**Files changed:** paper.tex (Section 5)

## Workstream 5: Covariate Balance (Grok, GPT)

**Action:** Acknowledge the limitation that pre-period balance on observables (opioid mortality, Medicaid expansion, baseline provider density) is not formally tested. Note that doubly-robust CS-DiD partially addresses this via propensity score reweighting.

**Files changed:** paper.tex (Section 4)

## Workstream 6: Estimator Sensitivity Diagnosis (GPT)

**Action:** Expand discussion of CS vs TWFE/stacked divergence. Explain heterogeneous treatment effects across cohorts, Bacon decomposition showing negative timing-comparison weights. State CS-DiD as preferred estimator while honestly reporting all three.

**Files changed:** paper.tex (Section 5.3)

## Verification

All changes are text-only revisions to paper.tex. No re-running of analysis code required. Changes documented in reply_to_reviewers_1.md.
