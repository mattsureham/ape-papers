# Reply to Reviewers — apep_0510 v1

## Reviewer 1 (GPT-5.2) — MAJOR REVISION

### 1. CS-DiD control group ambiguity
**Concern:** Unclear if CS-DiD uses never-treated only or not-yet-treated + never-treated.
**Response:** The `did` package default uses not-yet-treated + never-treated. We will clarify this in the empirical strategy section. The seven never-treated states supplement the not-yet-treated comparison units; results are not driven by them alone. We note this for future revision.

### 2. Harmonize inference across estimators
**Concern:** Large SE discrepancy between CS-DiD (1.186) and TWFE (0.388) for retention.
**Response:** This reflects the CS-DiD bootstrap procedure vs. analytical cluster SEs in TWFE, combined with the CS-DiD's aggregation over cohort-specific estimates. We have added a note in the power section clarifying this. Wild cluster bootstrap is a natural extension for future work.

### 3. Align covariates across CS-DiD and TWFE
**Concern:** TWFE includes controls but CS-DiD does not appear to.
**Response:** CS-DiD uses the doubly-robust estimator which incorporates covariates in both the propensity score and outcome regression. We will clarify this in the methodology. The covariate sets differ (CS-DiD uses within-group demeaning; TWFE includes explicit controls).

### 4. Recalibrate mortality/substitution claims
**Concern:** Mortality evidence is non-identified but used in abstract.
**Response:** **Accepted.** We have revised the abstract to remove mortality claims entirely, renamed the section to "Descriptive Evidence," and softened all language throughout the paper. The mortality analysis is now framed purely as descriptive context.

### 5. Enrollment-weighted estimates
**Noted for future revision.** Student-weighted ATTs would strengthen interpretation.

### 6. Exposure-heterogeneity tests
**Noted for future revision.** Interacting treatment with baseline overdose rates would be valuable.

---

## Reviewer 2 (Grok-4.1-Fast) — MINOR REVISION

### 1. Enrollment estimator tension
**Concern:** CS-DiD vs TWFE enrollment discrepancy needs cohort-specific decomposition.
**Response:** We have softened the interpretation to "does not survive alternative specifications." Cohort-specific ATTs are a natural extension for revision.

### 2. Never-treated balance
**Concern:** No pre-treatment balance table comparing treated vs never-treated.
**Response:** Noted for future revision. Summary statistics by mandate status (Table 1) provide partial evidence.

### 3. Move mortality to appendix
**Concern:** Mortality prominence despite descriptive status.
**Response:** We have significantly de-emphasized the mortality analysis in the abstract and renamed the section, but kept it in the main text as it provides important context for the substitution mechanism discussion.

### 4. Missing citations
**Concern:** Add Maclean et al. (2022) and Schwandt et al. (2024).
**Response:** Noted for future revision.

---

## Reviewer 3 (Gemini-3-Flash) — MINOR REVISION

### 1. Reconcile enrollment results
**Concern:** 10% enrollment increase is large; needs cohort decomposition.
**Response:** We have reframed the enrollment result as not surviving alternative specifications. The TWFE estimate (1.8%, p=0.15) suggests the CS-DiD result may reflect heterogeneous cohort weighting rather than a true treatment effect.

### 2. Clarify mortality findings
**Concern:** Abstract claims substitution, but Table 3 shows nulls.
**Response:** **Accepted.** Abstract revised to remove mortality claims. The substitution narrative is now presented as one of four possible mechanisms rather than the primary interpretation.

### 3. Intensive vs extensive margin
**Concern:** Need population-level enrollment rates.
**Response:** Noted as an important extension. ACS state-age enrollment rates would complement the IPEDS institution-level analysis.

---

## Changes Made in This Round

1. **Abstract revised** — Removed mortality/substitution claims, softened enrollment language to "does not survive alternative specifications," added MDE bounds.
2. **Section 5.3 renamed** — "First Stage" → "Descriptive Evidence: Overdose Mortality Trends" with explicit non-causal framing.
3. **All "first-stage" references removed** — Replaced with "descriptive evidence" or "mortality analysis" throughout.
4. **Pre-trends discussion strengthened** — Explicitly states the positive coefficient "cannot be interpreted as a causal effect."
5. **Opening hook improved** — Per prose review, replaced generic opening with vivid student-risk framing.
6. **Results narration improved** — De-jargoned the main results paragraph per prose review feedback.
7. **Figure consistency** — Standardized color scheme across Figures 1-2.
