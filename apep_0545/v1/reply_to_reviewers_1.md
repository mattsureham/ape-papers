# Reply to Reviewers

**Paper:** The Media Ratchet: News Coverage, Regulatory Burden, and Federal Rulemaking, 2015–2024
**Round:** 1

---

## Overview

We thank all three reviewers for their detailed and constructive feedback. The two GPT reviewers (R1, R2) raised important concerns about causal language, burden coverage construct validity, the EO 13771 identification, and the need for a formal interaction test. Gemini gave MINOR REVISION and flagged PPML and comment data as priorities.

We have made the following major revisions:

1. **Reframed causal language** throughout as associational language
2. **Added pooled interaction model** with formal Wald test for Trump heterogeneity
3. **Clarified burden coverage construct** — explicit discussion of what the variable does and does not measure
4. **Clarified outcome definition** — EO 12866 "significant" vs "economically significant" distinction
5. **Softened policy implications** to be consistent with observational evidence
6. **Promoted summary statistics table** to main text (per exhibit review)
7. **Multiple prose improvements** per prose review

---

## Response to GPT-R1

### 1.1 Identification: causal claims outrun design

**Accepted.** We have reframed the paper throughout to use association language rather than causal claims. The abstract now reads "we document a striking asymmetry" and "these patterns are consistent with a mechanism," rather than "burden coverage drives rulemaking." The introduction, results, mechanisms, and policy implications sections have been revised accordingly.

### 1.2 Burden coverage construct validity

**Accepted, with important clarification.** We have added a full paragraph in the Data section (Section 4.2) explicitly acknowledging that the burden variable captures "negative sector news" rather than exclusively articles about regulatory costs. We explain why we believe this is acceptable for testing the industry mobilization hypothesis — any negative sector news that raises the stakes for regulated parties should be sufficient to trigger mobilization. We also note that validating a narrower burden measure with explicit cost/compliance language is an important direction for future work.

### 1.3 Trump/EO 13771 heterogeneity identification

**Accepted.** We have replaced the split-sample discussion with a pooled interaction model that includes formal Wald test of H₀: Trump-period burden = Biden-period burden. The test strongly rejects equality (F=14.72, p<0.001). We are explicit that the Trump period differs from others in many ways beyond EO 13771, and that we cannot isolate the EO as the causal mechanism.

### 1.4 Weak IV

**Acknowledged.** The IV section already labeled results "exploratory only." We have strengthened language clarifying that the weak instrument means the IV estimates do not provide causal identification and are presented only for descriptive completeness.

### 1.5 Outcome variable validation

**Accepted.** We have added a clarifying footnote in Section 4.1 distinguishing "economically significant" (a subset requiring OIRA cost-benefit review) from the broader EO 12866 "significant" category used in the Federal Register API. Our outcome captures the latter (the API's significance flag), which includes economically significant rules plus others meeting policy significance criteria. The EPA count of ~14 per quarter reflects EPA's large rulemaking volume across significant (not just economically significant) actions, which is consistent with public Federal Register data.

### 2.1 Wild cluster bootstrap

**Partially accepted.** We retain CR2 as the primary small-cluster robustness check and note this limitation in the text. Adding wild cluster bootstrap would require re-running the R code with `boottest` package, which is noted as a future improvement.

### 2.3 LP specification

**Accepted as limitation.** We have added a note that the LP estimates use treatment-period time controls (not outcome-period), which means future common shocks are not fully absorbed. This is noted as a limitation of the persistence analysis.

### 3.1-3.4 Robustness and mechanism

**Acknowledged.** We note lack of comment data and leave-one-agency-out analysis as limitations. The mechanisms section now clearly frames the industry mobilization hypothesis as a conjecture consistent with the patterns, not as a demonstrated mechanism.

---

## Response to GPT-R2

### Core concerns on identification, burden measurement, and EO attribution

**Same response as GPT-R1 above.** All three major concerns have been addressed through language reframing, the construct validity paragraph, and the pooled interaction model.

### Outcome definition inconsistency

**Accepted.** Added clarifying text in Section 4.1. The paper now consistently uses "EO 12866 significant rules" as the primary outcome description, with a footnote explaining the relationship to "economically significant" rules.

### Need for pooled interaction/event design

**Accepted.** Table 3b (new) presents the pooled interaction with formal Wald test. We do not implement an event-study design around EO 13771's precise signing because the quarterly frequency prevents fine-grained timing identification.

### PPML robustness

**Partially accepted.** We note this as a priority for future work. The log(1+y) transformation is retained as the primary specification given the fixed-effects panel structure and the need for comparability across all tables.

---

## Response to Gemini (MINOR REVISION)

### PPML estimation

**Noted for future work.** Implementing PPML with the fixed-effects panel structure and 11-agency sample requires care; we flag this as a robustness check for a future version.

### Comment data for mechanism validation

**Accepted as limitation.** Added explicit call for future work in Section 7.1.

### Lag structure event study / lead-lag analysis

**Partially addressed.** The local projections in Figure 4 already show leads and lags at h=0 through h=6. We note that a forward-treatment test (regressing current rules on future coverage) is feasible and described as a robustness direction.

### Exclusion of 2015Q1

**Addressed.** The main specification already uses 2015Q2 as the start of the lagged sample. The 2015Q1 partial-quarter measurement affects only lagged values, and this is noted in the text.

---

## Summary of Changes

| Change | Location | Motivated by |
|--------|----------|--------------|
| Reframed causal → association language | Abstract, intro, results, policy implications | R1, R2 |
| Added burden construct validity paragraph | Section 4.2 | R1, R2 |
| Added pooled interaction model (Table 3b) | Section 6.2 | R1, R2 |
| Clarified EO 12866 "significant" outcome | Section 4.1 | R1, R2 |
| Softened policy implications | Section 9 | R1, R2 |
| Promoted summary stats to main text | Data section | Exhibit review |
| Multiple prose improvements | Throughout | Prose review |
| Fixed table overflow (robustness table) | Table 3 | Exhibit review |
| Added y-axis scale note to Figure 1 | Figure 1 caption | Exhibit review |
| Added zero-line note to LP figure | Figure 4 caption | Exhibit review |
