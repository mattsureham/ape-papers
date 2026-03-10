# Reply to Reviewers — apep_0584 v1

## Stage C Revision Summary

### Key Changes Made

1. **Joint Permutation Test (GPT R1 §1.2, GPT R2 §1, Gemini §1)**
   - Implemented a full joint permutation test for the symmetric sum
   - For each of 51 units, computed both Design 1 and Design 2 placebo ATTs and their sum
   - Joint RI p-value = 0.549, virtually identical to parametric estimate (0.552)
   - Estimated cross-design correlation ρ̂ = 0.30
   - Added correlation sensitivity analysis showing p ranges 0.42–0.65 across all ρ values

2. **Placebo-in-Time Test (GPT R1 §3.E, GPT R2 §2.6)**
   - Added January 2019 placebo treatment date using only pre-2021 data
   - Placebo ATT = 0.812 (p_RI = 0.628) — null result confirms no pre-treatment divergence

3. **Causal Language Calibration (GPT R1 §5, GPT R2 §5)**
   - Abstract: "raised" → "diverged from synthetic control"
   - Introduction: "increased" → "post-decriminalization divergence"
   - Results: Added caveats to "462 deaths" translation
   - Discussion: Softened Interpretation A language

4. **SE Methodology Transparency (GPT R1 §2.A, GPT R2 §2.A)**
   - Added explicit acknowledgment that placebo-SD SEs are not conventional sampling SEs
   - Stated RI p-values are the primary inferential object

5. **Drug-Specific Suppression Transparency (GPT R1 §3.B, GPT R2 §3)**
   - Added note that Oregon total OD deaths are never suppressed
   - Specified which drug categories are affected by suppression
   - Noted robustness to alternative suppression handling (83% → 82%)

6. **Exhibit Streamlining (Exhibit Review)**
   - Removed redundant Figure 6 (bar chart, duplicating Table 4)

### Issues Acknowledged but Not Fully Addressable

- **12-month rolling window contamination of Design 2**: Acknowledged in Section 4.6 and Discussion. Unsmoothed monthly data would require accessing restricted CDC files. The attenuation argument is maintained.
- **HB 4002 policy bundle**: Acknowledged in Section 2.3 and Discussion. Cannot be decomposed further with available data.
- **Drug-specific LOCF imputation**: Documented transparently; Oregon's key categories (fentanyl, psychostimulants) are unsuppressed.
