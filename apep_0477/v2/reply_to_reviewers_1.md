# Reply to Reviewers — apep_0477 v2

## Summary of Changes

This revision addresses the central concerns raised by all three reviewers through four main modifications:

1. **Reframed claims around identification credibility.** The abstract, introduction, and conclusion now center the C/D boundary as the cleanest causal evidence and present E/F as suggestive but limited by density manipulation. Language like "neither regulation nor information generates discrete price jumps" has been replaced with carefully qualified statements distinguishing clean from contaminated evidence.

2. **Full-sample estimation.** We now report boundary-specific RDD estimates using the full analysis sample (local windows around each cutoff), complementing the 500K-subsample results to confirm stability.

3. **Cluster bootstrap inference.** Decomposition, difference-in-discontinuities, and triple-difference standard errors are now computed via cluster bootstrap (200 replications, resampling districts), replacing the propagation-under-independence approach.

4. **Holm correction properly labeled.** The multiple testing correction is now correctly labeled as Holm (1979) stepdown, not as an approximation to Romano-Wolf.

---

## Reviewer 1 (GPT R1): REJECT AND RESUBMIT

### A. E/F manipulation invalidates sharp RDD
**Response:** We agree that E/F density manipulation limits the causal interpretation at this threshold. The revision restructures the paper to center C/D as the primary clean evidence and presents E/F as descriptive/suggestive. We have removed claims that "regulation doesn't move markets" and instead note that manipulation at E/F is itself informative about how the regulatory regime operates.

### B. Clean evidence limited to C/D
**Response:** Accepted. The revision explicitly states that the identified null is concentrated at C/D, with corroborating but non-causal evidence at other boundaries.

### C. Treatment not well-aligned with policy mechanism
**Response:** We acknowledge that the pooled analysis includes owner-occupied transactions where MEES does not bind. The revision notes this as a limitation and discusses tenure-specific estimates more carefully, emphasizing their imprecision.

### D. EPC timing/recency
**Response:** We add a discussion noting that EPC-to-sale lag is addressed in our mechanism analysis (lag RDD), and that restricting to EPCs issued >6 months before sale produces identical nulls.

### E. Diff-in-disc assumptions underdeveloped
**Response:** We add justification for using C/D as the temporal control and note that manipulation changes at E/F post-MEES could confound the diff-in-disc. The cluster bootstrap SEs now properly account for cross-estimator dependence.

### F. 500K subsample
**Response:** We now report full-sample local-window estimates alongside the subsample. Given discrete integer running variables, we use fixed-bandwidth local estimation on the full sample to demonstrate stability.

---

## Reviewer 2 (GPT R2): MAJOR REVISION

### A-C. E/F manipulation, sharp vs fuzzy treatment, tenure
**Response:** Same as our response to Reviewer 1 points A-C. The revision frames E/F as suggestive rather than causal and discusses the fuzzy regulatory exposure more carefully.

### D. Informational boundary interpretation
**Response:** We now explicitly distinguish threshold effects from continuous pricing throughout, including a clear statement that "the absence of threshold effects does not preclude smooth pricing of the continuous SAP score."

### E. Treatment timing
**Response:** We add discussion of the 2015 announcement and 2020 extension timing. The annual event study provides visual evidence on the evolution of estimates.

### F. Subsample
**Response:** Full-sample estimates now reported (see above).

### Inference issues (2A-E)
**Response:** Cluster bootstrap replaces propagation SEs for all derived estimands. Holm correction properly labeled. We add a note on the number of unique score support points in bandwidth discussions.

---

## Reviewer 3 (Gemini): MINOR REVISION

### Full-sample estimation
**Response:** Done. Full-sample local-window results reported.

### Price dynamics of sorted properties
**Response:** We discuss the implication that MEES may shift the cost of regulation to the investment required to reach band E rather than through price discounts.

### Score-price gradient interaction with crisis
**Response:** We note this as an interesting extension for future work. The current framework identifies threshold effects; estimating slope changes requires a different estimator.

---

## List of Changes

| Section | Change |
|---------|--------|
| Abstract | Rewritten to center C/D, qualify E/F, distinguish threshold vs continuous effects |
| Introduction | Reframed contribution; narrowed hedonic comparison; qualified E/F claims |
| Section 5.7 | Updated CIs to bias-corrected values |
| Section 6.1 | Added explicit numerical CIs for all boundaries |
| Section 6.4 | Text-table values aligned |
| Section 7.2 | Qualified polynomial consistency for B/C/A/B |
| Section 7.3 | Holm correction properly labeled |
| Section 8 | Conclusion rewritten with qualified claims |
| Tables | N added to polynomial, diff-in-disc; donut table empty cells fixed; bias-correction notes added |
| Code | Bootstrap inference added; full-sample estimation added; polynomial N added |
| References | Holm (1979) added |
