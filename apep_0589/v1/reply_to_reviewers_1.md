# Reply to Reviewers

## Reviewer 1 (GPT-5.4 R1) — REJECT AND RESUBMIT

### 1A. Estimand mismatch (withdrawal vs. threshold classification)
We have recalibrated the language throughout. The abstract, introduction, table labels, and equation notation now use "classified above 75%" rather than "graduated." The clarification paragraph in Section 4.1 explicitly states the RDD identifies the effect of threshold classification, not withdrawal restricted to graduates.

### 1B. Sharp vs. fuzzy RD
We now present a first-stage RDD in Appendix E (Table 5). The ERDF per capita discontinuity at the cutoff is not significant (p=0.26), reflecting the transition category's cushioning. We acknowledge this limitation explicitly in the Discussion and note that estimates capture the total classification effect including the safety net.

### 1C. Mean reversion from running variable / outcome overlap
We address this directly with a non-overlapping outcome specification (Appendix E, Table 5) that excludes 2008-2010 from the pre-period. The result (-3.14, p=0.228) is virtually identical to the EU-only baseline (-3.03, p=0.278), arguing against mechanical mean reversion as the primary driver. We also show a pre-2007 placebo with no discontinuity (p=0.30).

### 1D. Event study is not an RD event study
We have relabeled the event study as a "descriptive complement" and note explicitly that it does not flexibly control for the running variable by year. We no longer claim it "validates the continuity assumption" but instead describe it as "consistent with" the assumption.

### 1E. Candidate countries
We now report EU-only results (N=235) in Appendix E. The EU-only estimate is -3.03 (vs. -7.02 for the full sample), showing that candidate countries amplify the point estimate. We acknowledge this in the text.

### 1F. Institutional complications
We have expanded the Discussion to explicitly address the transition category, disbursement lags, and the inability to isolate ERDF from other funds.

---

## Reviewer 2 (GPT-5.4 R2) — REJECT AND RESUBMIT

### 2A. Mean reversion
Same as 1C above. Non-overlapping outcome yields similar results.

### 2B. Design does not isolate withdrawal
Same as 1A above. Language recalibrated throughout.

### 2C. Fuzzy RD / first stage
Same as 1B above. First-stage results now in appendix.

### 2D. Event study
Same as 1D above. Relabeled as descriptive.

### 2E. Candidate countries
Same as 1E above. EU-only results in appendix.

---

## Reviewer 3 (Gemini) — MAJOR REVISION

### 3.1. Donut RDD instability
We have expanded the donut discussion to explain the mechanical nature of the sign flip (removing 40-50% of near-cutoff observations). We acknowledge this as a genuine limitation of the small sample.

### 3.2. First stage
First-stage RDD now in Appendix E. The imprecise result motivates the interpretation as a classification effect rather than a sharp funding cutoff.

### 3.3. Country fixed effects
Noted as a valuable extension. The parametric specifications in the main text could be extended with country FE, though the nonparametric RDD remains the preferred estimator.
