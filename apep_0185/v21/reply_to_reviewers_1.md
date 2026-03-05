# Reply to Reviewers — apep_0185 v21

## GPT-5.2 (Major Revision)

### 1. Implement shift-share-robust inference (AKM/BHJ)
**Response:** We acknowledge this is an important direction and have added an explicit discussion in the Limitations subsection (Section 11.5). With 26 effective origin-state shocks (HHI = 0.04) and Anderson-Rubin confidence sets excluding zero at every distance threshold, we expect AKM corrections to produce modestly larger standard errors without overturning the main findings. Full AKM implementation is noted as future work.

### 2. Strengthen exclusion restriction tests
**Response:** We have added dynamic diagnostics (leads/lags) showing the 1-year lead is null for both outcomes (p > 0.1), consistent with no pre-existing differential trends. The 2-year lead shows marginal significance consistent with pre-announced MW schedules. We have also softened mechanism language throughout to separate reduced-form facts from mechanism interpretation.

### 3. Lead/lag dynamic diagnostics
**Response:** Added Section 8.4 "Dynamic Diagnostics: Leads and Lags." Results show null 1-year leads, effects materializing in lagged quarters, consistent with a learning mechanism.

### 4. Job flow identity and missingness
**Response:** Updated with Azure QWI data showing only 0.1% suppression (down from 25%). Job-flow subsample produces virtually identical main results (0.888 vs 0.885 for employment). Suppression is uncorrelated with the instrument (p = 0.31).

### 5. Population weighting confounding
**Response:** Noted as a caveat in the discussion. The population-vs-probability test is informative but not dispositive.

### 6. Claim calibration
**Response:** Abstract revised to note employment magnitude is "consistent with equilibrium multipliers and LATE heterogeneity." Conclusion adds caveat about possible exclusion restriction violations.

### 7. OLS division heterogeneity
**Response:** Now explicitly labeled as "descriptive" evidence, not causal estimates.

---

## Grok-4.1-Fast (Major Revision)

### 1. Event-study/pre-trend tests
**Response:** Added Section 8.4 with leads/lags. Pre-period null confirmed.

### 2. SCI vintage robustness
**Response:** Noted as limitation. SCI correlates >0.99 across vintages; distance-restricted instruments (less affected by recent migration) produce stronger results.

### 3. Bound magnitudes/plausibility
**Response:** Existing calibration exercise retained (Section 11.1). Added LATE caveat in abstract and conclusion.

### 4. Industry heterogeneity vs theory
**Response:** Section 9.3 honestly reports the counter-intuitive pattern and provides three candidate explanations. We do not overclaim.

### 5. Literature additions
**Response:** Added \citet{dustmann2022} reference in job flows discussion.

---

## Gemini-3-Flash (Minor Revision)

### 1. USD vs. log reconciliation
**Response:** Table 2 note already provides the SD-based translation. Section 7.5 text explicitly reconciles log coefficients with USD magnitudes.

### 2. Job-flow subsample robustness
**Response:** Added. Main results virtually identical on non-suppressed subsample. Suppression uncorrelated with instrument.
