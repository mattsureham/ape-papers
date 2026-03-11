# Reviewer Response Plan — Stage C Revision

**Paper:** apep_0591 v1 — The Erasmus Drain
**Date:** 2026-03-11
**Reviewer decisions:** GPT R1: REJECT AND RESUBMIT, GPT R2: MAJOR REVISION, Gemini: MINOR REVISION

## Common Themes Across Reviewers

### 1. Treatment Timing (GPT R1 §1.1, GPT R2 §A)
**Concern:** Contemporaneous outflow rate matched to stock outcome (tertiary share 25-34) — mechanism is about delayed non-return but specification uses no lags.
**Assessment:** Valid concern. Cannot fully address without major redesign (lagged/cumulative treatment, cohort-based exposure).
**Action:** Acknowledge explicitly as the paper's primary limitation. Add paragraph in Empirical Strategy explaining why contemporaneous specification is a reduced-form approximation. Soften causal interpretation throughout. Frame the coefficient as capturing the association between outflow intensity and human capital composition rather than a clean structural parameter.

### 2. Share Exogeneity Not Demonstrated (GPT R1 §1.2b, GPT R2 §B.1)
**Concern:** Pre-period shares likely reflect university quality, language links, migration corridors. Pre-trend test overlaps share-construction period.
**Assessment:** Valid. Cannot construct earlier shares (data starts 2014).
**Action:** Acknowledge limitation of pre-trend test timing more explicitly. Add discussion of what shares plausibly capture (institutional partnerships, not economic conditions). Be more honest about what "share exogeneity" requires vs. what we can demonstrate. Add country-year FE as robustness check (new R code).

### 3. RI p=0.446 Interpretation (GPT R1 §1.2a, GPT R2 §B.2, Gemini §2)
**Concern:** Paper still frames RI result as informative rather than problematic.
**Assessment:** Already improved in prior revision. Reviewers want even more caution.
**Action:** Further tone down. Make clear this is a genuine limitation. Remove any residual language suggesting the RI result "supports" identification.

### 4. AKM Inference (GPT R1 §2.1, GPT R2 §B)
**Concern:** Region-clustered and two-way clustered SEs insufficient for shift-share designs.
**Assessment:** Valid but AKM implementation requires specialized R packages not readily available.
**Action:** Acknowledge this limitation. Elevate two-way clustered SE to primary inference throughout (p≈0.05 rather than p=0.004). Report confidence intervals in text.

### 5. Causal Claims Too Strong (GPT R1 §5, GPT R2 §5A)
**Concern:** Abstract says "the answer is yes"; conclusion says "the drain is real."
**Assessment:** Valid. Must recalibrate throughout.
**Action:** Systematic toning down of all causal/mechanism language. "Suggestive evidence" not "definitive." Remove "first causal evidence" claim. Soften policy prescriptions.

### 6. Cohort Dilution Test Not Decisive (GPT R1 §3.1, GPT R2 §3A)
**Concern:** Any youth-specific shock would produce similar age differential.
**Assessment:** Valid.
**Action:** Acknowledge limitation in text. Frame as "consistent with" mechanism rather than "ruling out" alternatives.

### 7. Long-Difference Sign Flip (GPT R1 §3.4, GPT R2 §3B)
**Concern:** Cross-section IV flips positive — not just a power issue.
**Assessment:** Valid concern.
**Action:** Discuss more carefully. Acknowledge sign instability as a limitation rather than dismissing as power.

### 8. Magnitude Explanation (Gemini §5, GPT R2 §5B)
**Concern:** Coefficient implies 4x mechanical effect — why?
**Action:** Add decomposition discussion. Explain the multiplier could reflect: (a) Erasmus as proxy for broader mobility, (b) peer effects on non-participant migration, (c) treatment proxying cumulative rather than annual exposure.

### 9. F-Statistic Inconsistency (GPT R1 §2.2, GPT R2 §2A, Gemini §2)
**Concern:** Wald F=1,376 vs t²≈97 from standalone first-stage.
**Assessment:** Already addressed with footnote. Reviewers want more.
**Action:** Demote the 1,376 number. Report t²≈97 as the primary first-stage diagnostic. State that "the first-stage F-statistic under cluster-robust variance estimation is approximately 97."

### 10. Prose & Exhibit Improvements
- Move NUTS3 record count from intro (prose review)
- Professionalize Table 2 FE labels (exhibit review)
- Fix contributor placeholders

## Execution Order

1. Edit R code: add country-year FE, formal heterogeneity interaction test
2. Re-run analysis scripts (03, 04, 05, 06)
3. Comprehensive paper.tex rewrite:
   - Abstract: soften claims, elevate two-way SE
   - Introduction: remove "first causal evidence," soften causal language
   - Empirical Strategy: add timing discussion, acknowledge limitations
   - Results: add CIs, soften mechanism claims, better dilution test framing
   - Discussion: add magnitude decomposition, soften RI section
   - Conclusion: reframe as "suggestive evidence"
   - Fix contributor placeholders
4. Recompile PDF
5. Write reply_to_reviewers_1.md
