# Reviewer Response Plan (Round 1)

**Generated:** 2026-03-09
**Reviews:** GPT-5.4 R1 (MAJOR), GPT-5.4 R2 (MAJOR), Gemini (MINOR)

---

## Converging Concerns (All 3 Reviewers)

### 1. Short-panel mechanism results not credible
**R1:** "should not be treated as credible"; "admission that inference may be invalid"
**R2:** "not publication-ready"; "paper cannot simultaneously flag inference as unreliable and interpret results"
**Gemini:** "likely spurious"; "de-emphasize and emphasize the long-panel null"

**Action:** Demote mechanism results from abstract and introduction. Frame as "exploratory" in results section. Remove significance-based interpretations. Add explicit caveat that influence-function SEs may understate uncertainty with 9 treated clusters.

### 2. 2018 data gap is a first-order identification issue
**R1:** "much more consequential than the paper suggests"; "cannot identify immediate effects for the largest adoption wave"
**R2:** "central identification problem, not a footnote"
**Gemini:** "sensitivity excluding the 8 states that adopted in 2018"

**Action:** Add robustness check excluding 2018 cohort from estimation. Show long-panel ATT is robust. Expand discussion of 2018 gap as identification concern.

### 3. Concurrent policy confounding unaddressed
**R1:** "most important missing robustness exercise"
**R2:** "Without accounting for this, the paper cannot claim ERPO-specific causal effect"
**Gemini:** (implicit in COVID controls suggestion)

**Action:** Expand concurrent-policy discussion in Section 6.5. Add RAND State Firearm Law Database reference. Acknowledge this is a limitation that constrains interpretation. Note that CS-DiD with not-yet-treated controls partially addresses this (Table 3).

### 4. Pre-trend diagnostics too weak
**R1:** "no formal joint pre-trends test reported"
**R2:** "no joint test; only pointwise bands"

**Action:** Add formal joint pre-trend test (F-test on pre-treatment coefficients). Report in text and appendix.

### 5. Claim calibration too strong
**R1:** "no statistically detectable average effect, not precisely estimated null"
**R2:** "interpreted too confidently"
**Gemini:** "re-center narrative"

**Action:** Replace "precisely estimated null" throughout with "no statistically detectable effect." Moderate language on what the CI rules out. Soften policy prescriptions.

---

## Additional Concerns (2 of 3 Reviewers)

### 6. Population-weighted estimates (R1, R2)
**Action:** Add population-weighted CS estimate as robustness check.

### 7. Data source comparability validation (R1, R2)
**Action:** Add paragraph in data section discussing coding consistency between NCHS and CDC Mapping Injury. Note both derive from NVSS death certificates.

### 8. Anti-ERPO control group (R1, R2)
**Action:** Add robustness check excluding anti-ERPO states. Discuss in text.

### 9. Alternative staggered estimators (R1, R2)
**Action:** Acknowledge in text as limitation. Note that the paper already compares CS-DiD with TWFE and not-yet-treated controls. Adding Sun-Abraham or BJS is beyond scope of this revision but would strengthen future work.

### 10. Adoption vs implementation language (R1, R2)
**Action:** Tighten language throughout to "ERPO adoption" not "ERPO effects."

---

## Prose Workstream (from Exhibit + Prose Reviews)

### Already addressed in prior rounds:
- Removed internal figure titles (Figures 3, 4)
- Sorted leave-one-out by coefficient
- Removed CI brackets from Table 2
- Improved results opening ("ERPO laws do not reduce...")

### Still to address:
- Punchier opening paragraph (Shleifer hook)
- Shorten roadmap sentence
- Strengthen data section prose (measurement logic)
- Moderate TWFE bias rhetoric ("illustrative" not "demonstrates")

---

## Exhibits Workstream

### Already addressed:
- CI brackets removed from Table 2
- Internal titles removed from figures
- Leave-one-out sorted by coefficient

### Still to address:
- Move Table 4 (leave-one-out table) to appendix
- Thicken zero-line in Figure 1
- Add vertical dashed line at 2018 in Figure 6

---

## Code Changes Required

1. `04_robustness.R`: Add sensitivity excluding 2018 cohort
2. `04_robustness.R`: Add population-weighted CS estimates
3. `04_robustness.R`: Add sensitivity excluding anti-ERPO states
4. `03_main_analysis.R`: Add formal joint pre-trend test
5. `06_tables.R`: Generate new robustness table rows
6. `05_figures.R`: Thicken zero-line in Figure 1; add 2018 line to Figure 6

---

## Execution Order

1. Code changes (robustness checks)
2. Run all R scripts
3. Paper.tex revisions (abstract, intro, results, discussion, conclusion)
4. Move Table 4 to appendix
5. Recompile PDF
6. Write reply_to_reviewers_1.md
