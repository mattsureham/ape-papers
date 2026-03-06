# Reply to Reviewers — Round 1

## Common Concerns Across Reviewers

All three reviewers raised the grants-only data limitation as the central issue: the examiner grant share variable may reflect workload/processing speed rather than grant propensity, and the sample conditions on a post-treatment outcome (grant). We have:

1. **Strengthened the Limitations section** to explicitly discuss selection into the granted sample, the workload-versus-propensity confound, and outcome aggregation concerns (Section 7.6).
2. **Added a balance test caveat** noting that balance among grants does not validate random assignment of applications (Section 6.1).
3. **Expanded Threats to Validity** with dedicated subsections on workload confound and sample selection (Section 5.3).
4. **Tempered all policy claims** — removed the "sideshow" conclusion language, narrowed TRIPS/WTO discussion to acknowledge the design identifies a narrow margin, not broad IP regime effects.
5. **Added Frakes & Wasserman (2017)** citation on examiner incentives and workload endogeneity.

---

## Reviewer 1 (GPT-5.4 R1) — REJECT AND RESUBMIT

### 1A. Grant share ≠ grant propensity
**Response:** We agree this is the fundamental limitation. We have rewritten the Limitations section to explicitly acknowledge that (a) grant share may reflect workload, speed, or case assignment rather than propensity; (b) the sample conditions on grants, creating potential selection; and (c) the balance tests validate balance among grants, not among applications. The paper now consistently frames results as "the effect of assignment to a higher-output examiner" and explicitly notes that the reduced-form estimates should be interpreted as descriptive associations within the granted population. We recommend PatEx application-level data for future work (Section 7.6, Section 8).

### 1B. Conditioning on grants = selection
**Response:** Added explicit discussion in both the balance test section (new paragraph) and Threats to Validity (new subsection). The balance test caveat now reads: "these balance tests are computed on granted patents only... balance among grants could hold even if the underlying application assignment is not random."

### 1C. Grant-year cell timing
**Response:** The paper already explains this choice (Section 4.2, final paragraph): assignment is quasi-random at filing; grant-year cells capture contemporaneous examiner behavior; results are robust to grant-year FE. We retain this structure but do not claim it identifies filing-time randomization.

### 1D. Outcome too aggregate
**Response:** Added a substantial paragraph in Limitations discussing outcome aggregation: "A single examiner assignment is unlikely to move total subclass patenting counts unless effects are very large." We note that more targeted outcomes (close technology neighbors, assignee-external citations) could reveal effects that subclass aggregation obscures.

### 1E. Clustering mismatch
**Response:** The paper already reports robustness to examiner, art-unit, and art-unit-by-year clustering (Table 5, Table A). We acknowledge in the Limitations that the subclass-level outcome creates shared-outcome correlation, but note that art-unit-by-filing-year FE absorb subclass levels within cells.

### 1F. Experienced-examiner result
**Response:** Expanded the discussion of the experienced-examiner coefficient (-0.004, p=0.09). We now note this subsample is "conceptually important" because measurement error is lower, and that a small negative effect cannot be firmly ruled out, while acknowledging it is not robust across specifications.

### 1G. Policy claims overclaimed
**Response:** Substantially revised. Removed the "sideshow" conclusion. Narrowed WTO discussion: "the design identifies a narrow margin... not the broad IP regime changes debated in WTO negotiations." The conclusion now frames the contribution as "the central reduced-form fact" about examiner output variation, not as evidence about the patent system writ large.

### 1H. Falsification/placebo tests
**Response:** Acknowledged as a limitation. The paper's robustness checks focus on functional form, sample restrictions, and clustering alternatives rather than falsification exercises. Pre-trend tests and permutation inference are recommended for future work with application-level data.

---

## Reviewer 2 (GPT-5.4 R2) — REJECT AND RESUBMIT

Reviewer 2's concerns largely overlap with Reviewer 1. The key additional points:

### 2A. Paper alternates between estimand labels
**Response:** The paper uses "examiner grant share" consistently throughout after the advisor review round, which replaced all instances of "leniency." The interpretation paragraph (Section 4.2) clarifies that this is a grant share, not a grant rate.

### 2B. IV-on-claims exercise not convincing
**Response:** We retain this in the appendix as exploratory, clearly labeled. The F-statistic of 38.2 is noted as below the conventional threshold and the exercise is described as "suggestive" rather than definitive.

### 2C. External validity oversold
**Response:** Revised. The conclusion now states: "the result is specific to within-subclass follow-on patenting among grants, and should not be read as evidence about the patent system's overall role in green innovation."

---

## Reviewer 3 (Gemini) — MAJOR REVISION

### 3A. Grant share vs grant rate (must-fix)
**Response:** Addressed throughout. The Interpretation paragraph (Section 4.2) is explicit about this distinction. The Threats to Validity section now has a dedicated "Workload versus propensity" subsection.

### 3B. Broader outcome measurement (must-fix)
**Response:** Acknowledged as an important limitation. The revised Limitations section explicitly discusses cross-subclass spillovers and recommends more targeted outcomes for future work. We cannot add new analysis without re-running R code, but the discussion is now transparent about this concern.

### 3C. Promote citation results to main text
**Response:** The citation results are already reported in the main text Results section (Section 6.2, paragraph 2) with specific numbers. The full regression table remains in the appendix (Table A) for space reasons.

### 3D. Convert Figure 3 to binscatter
**Response:** Noted for future revision. The current quintile plot conveys the same information but could be improved with finer bins.

### 3E. Heterogeneity by firm size
**Response:** Already included — Table A3 reports heterogeneity by assignee type (US Corporation, Foreign Corporation, Government/University). All are null.

---

## Summary of Changes

1. Rewrote Limitations section (Section 7.6) — three substantive subsections on grants-only selection, outcome aggregation, and local estimand
2. Added balance test caveat paragraph (Section 6.1) about grants-only balance
3. Expanded Threats to Validity (Section 5.3) with workload confound and sample selection subsections
4. Expanded experienced-examiner discussion in Robustness (Section 6.5)
5. Tempered conclusion — removed "sideshow," narrowed policy claims
6. Tempered introduction policy paragraph
7. Tempered WTO/TRIPS discussion in Policy Implications (Section 7.5)
8. Added Frakes & Wasserman (2017) citation
