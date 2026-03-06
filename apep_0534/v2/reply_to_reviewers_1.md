# Reply to Reviewers — apep_0534 v2

**Paper:** Does Examiner Leniency Affect Cumulative Green Innovation?
**Version:** v2 (revision of v1)
**Date:** 2026-03-06

---

## Reviewer 1 (GPT-5.4 R1): Reject & Resubmit

### 1A. "Outcome-treatment mismatch: 640K observations share 96 unique outcome values"

**Response:** We agree this is the central design challenge. The revision restructures the paper around this reality:
- The collapsed subclass×filing-year analysis (96 cells) is now the primary evidence (Table 6 Panel C), with the subclass-year collapse yielding −0.193 (p=0.025) and the art-unit-year collapse yielding a null (−0.011, SE=0.014).
- Application-level results are presented as supplementary, with explicit caveats that p-values overstate precision due to the shared-outcome structure.
- The abstract and conclusion now state that "the evidence does not support the conclusion that marginal patent-office decisions are a binding constraint on cumulative green innovation."

### 1B. "Collapsed analyses do not rescue identification"

**Response:** We agree. The revised paper explicitly states that "this collapsed estimate does not inherit the application-level random-assignment guarantee" (Abstract, Section 7.5). We do not claim the subclass-year collapse is causally identified. Instead, we present both collapses transparently and conclude the evidence is too sensitive to aggregation for a firm causal claim.

### 1C. "Follow-on outcome is conceptually too aggregate for the causal question"

**Response:** We agree that application-specific downstream measures would be superior. The revised Discussion (Section 8.3) now explicitly acknowledges this limitation: "prior examiner-IV studies use application-specific outcomes... our CPC subclass aggregate is considerably coarser." Constructing text-similarity-weighted or citation-linkage outcomes is noted as a priority for future work but is beyond the scope of this revision.

### 1D. "Quasi-random assignment asserted more than demonstrated"

**Response:** We acknowledge that the current balance tests (Table 3) are limited to the grants subsample. The revision adds a note explaining this is post-treatment selection. Richer pre-treatment covariates from PatEx (continuation status, inventor count) would strengthen validation but are not available in the current BigQuery extract. We now frame the assignment validation as relying primarily on institutional arguments and prior validation in the literature.

### 1E. "Subclass imputation for abandoned applications"

**Response:** The revision acknowledges this more prominently as a limitation (Section 8.4). We note that modal-subclass imputation may introduce nonclassical measurement error and that the direction of bias is not established. Sensitivity to high-purity art units (≥90% Y02) is discussed in robustness.

### 1F. "Timing does not align with blocking mechanism"

**Response:** The revision consistently frames the reduced form as an ITT of examiner assignment from filing onward, not a post-grant blocking effect. Language referring to "blocking" has been removed or qualified throughout. The estimand section (Section 5) now explicitly states this is an ITT interpretation.

### 1G. "IV interpretation not credible"

**Response:** IV estimates are now labeled "exploratory" and preceded by an explicit disclaimer: "should NOT be interpreted as causal effects of the grant decision" (Section 6.5). The exclusion restriction concern is acknowledged upfront.

### Must-Fix Items 1-5 from R1 §6:

| Item | Status |
|------|--------|
| 1. Redesign outcome to application-specific | Acknowledged as future work; beyond current revision scope |
| 2. Rebuild inference at correct level | Collapsed analysis is now primary; application-level demoted |
| 3. Strengthen balance validation | Acknowledged as limitation; institutional argument strengthened |
| 4. Address classification/imputation | Discussed more prominently; sensitivity to high-purity art units added |
| 5. Reframe timing as ITT | Done throughout |

---

## Reviewer 2 (GPT-5.4 R2): Reject & Resubmit

### 2A. "Causal estimand not cleanly matched to outcome"

**Response:** We agree fully. The revision no longer presents the application-level reduced form as a well-defined causal estimate of grant effects on innovation. The paper is reframed as methodological (PatEx enables proper first stage) and descriptive (downstream evidence is mixed and sensitive to aggregation).

### 2B. "Subclass-by-year collapse does not preserve identification"

**Response:** Agreed. The paper now states this explicitly: "this collapsed estimate does not inherit the application-level random-assignment guarantee" (Abstract). We do not claim the collapsed estimate is causally identified.

### 2C. "Abandonment subclass imputation is a major threat"

**Response:** The revision elevates this concern in the Discussion (Section 8.4) and acknowledges that modal-subclass imputation may be nonclassically mismeasured. Obtaining subclass data from PAIR file-wrapper text would require a separate data infrastructure project beyond this revision's scope.

### 2D. "IV exclusion not credible"

**Response:** IV estimates are now "exploratory under strong assumptions." The revision starts the IV section with a disclaimer and presents IV results as scaling exercises, not causal grant effects.

### 2E. "Filing-date timing weakens blocking interpretation"

**Response:** Blocking language removed. Estimand consistently defined as ITT from filing onward.

### 2F-2G. "Application-level SEs invalid; alternative clustering does not solve the problem"

**Response:** The revision leads with collapsed estimates. Application-level results are supplementary with explicit pseudo-replication caveats. The alternative clustering table (Table 7) is retained to show that two-way clustering renders the result insignificant, reinforcing the fragility of application-level inference.

### 2H. "Placebo test not informative"

**Response:** We agree the other-subclass placebo is mechanically linked to the main outcome. The revision honestly reports the significant placebo result (coef=0.001, SE=0.000310) and interprets it as a mechanical complement rather than a design violation.

### Must-Fix Items 1-5 from R2 §6:

| Item | Status |
|------|--------|
| 1. Rebuild outcome at coherent level | Application-specific outcomes noted as future work |
| 2. Eliminate/validate subclass imputation | Elevated as limitation; high-purity sensitivity added |
| 3. Move inference to correct unit | Collapsed analysis is primary |
| 4. Reassess identification for collapsed design | Explicitly acknowledged as not inheriting random assignment |
| 5. Remove/demote IV grant-effect estimates | IV labeled exploratory with non-causal disclaimer |

---

## Reviewer 3 (Gemini-3-Flash): Major Revision

### 3A. "Aggregation discrepancy is the smoking gun"

**Response:** We agree this is the most telling result. The revision presents both collapses (subclass-year: significant; AU-year: null) as co-equal evidence and concludes: "the evidence is too sensitive to the level of aggregation to support a firm causal conclusion."

### 3B. "Clustering adjustment needed"

**Response:** Table 7 shows that two-way clustering (Examiner × CPC) renders the application-level result insignificant. The revision elevates this from a robustness check to supporting evidence for the fragility of application-level inference.

### 3C. "Balance test expansion"

**Response:** Acknowledged as a limitation. Continuation status and inventor count from PatEx would strengthen validation but are not available in the current extract.

### 3D. "Sample period and post-Paris Agreement era"

**Response:** The Discussion (Section 8.4) now notes the 2001-2012 sample period limitation and the possibility that post-Paris Agreement dynamics differ.

### Must-Fix Items from R3 §6:

| Item | Status |
|------|--------|
| 1. Address aggregation discrepancy | Both collapses presented transparently; mixed conclusion |
| 2. Clustering adjustment | Two-way clustering shown; application-level results demoted |

### High-Value Items from R3 §6:

| Item | Status |
|------|--------|
| 1. Balance test expansion | Acknowledged as limitation |
| 2. Cross-subclass redirection mechanism | Noted as future work direction |
| 3. Sample period discussion | Added to Discussion |
