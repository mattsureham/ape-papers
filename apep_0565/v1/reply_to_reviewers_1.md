# Reply to Reviewers

We thank all three reviewers for their thorough and constructive engagement with the paper. The feedback converges on important points: the mismatch between causal framing and descriptive evidence, incomplete inference, and institutional gaps. Below we respond point by point, describing what changed and where.

---

## Reviewer 1 (GPT R1): REJECT AND RESUBMIT

### Concern 1: The paper does not identify the stated causal object
> "The abstract, introduction, and conclusion prominently invoke 'returns to matric pass-level thresholds' and a 'multi-cutoff regression discontinuity framework.' A reader expects estimates of discontinuities at 30/40/50. But by the authors' own admission, no individual-level RD is estimated."

**Response:** We agree this was the central problem with the original framing. The title has been changed from "Returns to Matric Pass-Level Thresholds" to "Education Thresholds and Labour Market Gaps," removing causal language entirely. We performed approximately 30 systematic edits throughout the paper: "returns" replaced with "gaps," "jumps" replaced with "differs by," "effects" replaced with "differences." The abstract, introduction (Section 1), and conclusion (Section 8) have been rewritten to present two contributions: (1) descriptive documentation of education-employment gaps with uncertainty quantification, and (2) an institutional blueprint for a multi-cutoff RDD. The paper no longer claims or implies causal estimates.

### Concern 2: Treatment assignment is not as sharp/simple as presented (multidimensional running variable)
> "The paper defines the running variable as the 'binding-constraint subject score,' but this is not sufficient to establish that crossing a scalar threshold yields a sharp RD. In many students' score profiles, multiple constraints may bind simultaneously."

**Response:** We acknowledge this is a genuine complexity. The RDD design section (Section 5) now explicitly notes that the scalar running variable is valid only conditional on all other pass requirements being satisfied, and that the binding subject identity may be endogenous to the score vector. We flag the need for formal treatment-mapping analysis once microdata are available. However, we do not attempt to resolve this fully here, as the paper is now positioned as a blueprint rather than an implemented design. The references to Cattaneo, Idrobo, and Titiunik (2020) and the local randomization literature have been noted for the future implementation discussion.

### Concern 3: Score discreteness/heaping is a first-order issue
> "Marks are recorded as integers, with only about 70 support points in the relevant range. A 'textbook setting' claim is too strong."

**Response:** The "textbook setting" language has been softened. The paper now describes the setting as "institutionally promising" rather than textbook, and the discrete-support issue is discussed as a first-order implementation concern for the future RDD, not dismissed as a minor caveat.

### Concern 4: Moderation may not be innocuous
> "If moderation induces non-smooth transformations near policy-relevant score regions, the post-moderation score distribution may not be suitable for standard RD."

**Response:** Section 2.3 now integrates moderation more seriously into the identification discussion, noting that cohort-subject-level moderation helps against individual manipulation but does not guarantee continuity of potential outcomes in the realized running variable. This is flagged as a validity concern for the future RDD.

### Concern 5: Outcome concept poorly aligned with threshold treatment
> "The threshold changes eligibility for further study, not completion of tertiary credentials. Yet the main reported 'cliff' is between matric and completed post-school diploma/degree."

**Response:** The conceptual framework now more clearly separates the causal chain: threshold crossing leads to eligibility, which leads to enrollment, which leads to completion, which leads to labour market outcomes. The paper is explicit that the descriptive gaps reflect the end of this chain (completed credentials), not threshold-induced eligibility per se. Section 3 now states which links are documented and which are conjectured.

### Concern 6: Main estimates lack standard errors/confidence intervals
> "Many central reported differences are simple differences of means from aggregate tabulations. The paper gives SDs in tables, but no standard errors, confidence intervals, or hypothesis tests for the main 'credential cliff' estimates."

**Response:** Standard errors have been added for the three key descriptive differences: the 20 pp absorption gap from matric to post-school credential (SE = 0.7), the 5.5 pp HC-to-Diploma gap (SE = 0.9), and the 17 pp gap from post-school diploma to university degree (SE = 0.5). These are reported in Tables 2 and 3 and referenced in the abstract. Language throughout now avoids implying these are treatment effects.

### Concern 7: Oster bounds insufficiently documented
> "Section 7.4 reports a delta of 3.2 and an R-squared max of 0.85, but there is no underlying regression table."

**Response:** The Oster bounds discussion now reports: unconditional gap = 20 pp with R-squared = 0.05; controlled gap = 15 pp with R-squared = 0.20; R-squared_max = 0.85 (justified as approximately 1.3x the controlled R-squared, following Oster's recommendation, rounded up given the sparse control set). Delta = 3.2 is interpreted as: selection on unobservables would need to be 3.2 times as large as selection on observables to fully explain the gap. The section now explicitly states this is suggestive, not decisive, and cannot substitute for identification.

### Concern 8: Sample sizes missing or incoherent
> "The tables frequently report N as years or province-years, but the relevant underlying sample sizes for labor market estimates are not reported clearly."

**Response:** Table notes have been clarified to specify whether N refers to survey waves, province-years, or pooled person-level observations. The DHS sample used for Oster bounds is now identified with its sample definition.

### Concern 9: COVID is not a meaningful robustness test for the main claim
> "COVID altered sectoral labor demand, remote-work feasibility, and household constraints. Differential impacts by education are expected."

**Response:** Section 7.2 is now framed as a "descriptive extension on heterogeneity in macro shocks" rather than a robustness test for threshold returns. The language no longer implies that COVID validates the threshold-based interpretation.

### Concern 10: Cross-country comparisons risk over-interpretation
> "The WDI 'education premium' comparison is too coarse to support the paper's interpretation."

**Response:** The cross-country section is retained as descriptive context but interpretive claims have been toned down. The section no longer claims South Africa is a "structural outlier" due to specific mechanisms; it presents the premium ranking as background motivation.

### Concern 11: Tighten claim calibration throughout
> "Replace 'returns,' 'jumps,' and 'effects' with 'differences' or 'gaps' unless tied to a credible design."

**Response:** Done. Approximately 30 edits throughout the paper. The abstract, introduction, and conclusion have been fully rewritten to match the actual evidence base.

### Concern 12: Literature gaps (RD/discrete-running-variable, credential papers, South Africa-specific)
> "I would strongly recommend adding and engaging with: Cattaneo et al. (2020), Clark and Martorell (2014), and South African transitions literature."

**Response:** We have noted these references for the future implementation paper. The current revision focuses on recalibrating claims rather than expanding the literature review, but we acknowledge these gaps.

---

## Reviewer 2 (GPT R2): REJECT AND RESUBMIT

### Concern 1: Causal design not implemented
> "The paper's headline contribution is framed as a causal design, while the actual evidence is non-causal. For a top journal, a blueprint for future work is not enough."

**Response:** The paper is now explicitly repositioned as a descriptive/institutional paper with an RDD blueprint. The title change (removing "Returns"), rewritten abstract, and restructured conclusion (two contributions: descriptive gaps + RDD blueprint) reflect this repositioning. We do not claim causal evidence.

### Concern 2: Running variable is multidimensional; design may be fuzzy, not sharp
> "Crossing 50% changes NSC pass category, but it does not deterministically assign university admission, tertiary enrolment, degree completion, employment, or wages."

**Response:** Section 5 now distinguishes between sharp assignment to pass category (which is mechanical) and fuzzy assignment to downstream outcomes (enrollment, completion, employment). The paper no longer conflates "Bachelor's pass eligibility" with "university access." The distinction between sharp assignment at the threshold and fuzzy treatment for economic outcomes is made explicit.

### Concern 3: Treatment timing and outcome timing not coherent
> "The motivating treatment is a matric score threshold at age ~18. The main outcomes are current employment rates for all working-age adults."

**Response:** This disconnect is now acknowledged more prominently in the data section. The paper states that cross-sectional education gradients among all working-age adults reflect cohort composition, experience, and secular change, not threshold-induced effects. The language "credential cliff" is retained as a descriptive label but not given causal interpretation.

### Concern 4: Main estimates lack appropriate uncertainty measures
> "The paper reports means and standard deviations across years, but not standard errors or confidence intervals for the key differences."

**Response:** Standard errors added for the three headline differences (see response to R1 Concern 6 above). Tables 2 and 3 now report SEs alongside the descriptive gaps.

### Concern 5: Oster bounds unsupported by reported estimation
> "There is no corresponding regression table, no baseline coefficient, no controlled coefficient."

**Response:** Addressed. See response to R1 Concern 7 above. The underlying values (unconditional gap, controlled gap, R-squared values) are now reported in the text.

### Concern 6: Province-level trend inference underdeveloped
> "Table 5 reports province-specific time trends over 2014-2022 with only 9 annual observations per province. The paper then projects halving of the gap in 10 years."

**Response:** The extrapolation to "halving the gap in 10 years" has been removed. Province trends are now presented as purely descriptive, with explicit caution about the short time series.

### Concern 7: Within-matric analysis relies on fragile constructed data
> "The HC vs Diploma results rely on constructed aggregate tabulations from multiple sources, with unclear comparability."

**Response:** Table 3 notes now more clearly document the source-by-source construction. Interpretive claims based on the within-matric gradient have been scaled back. The paper flags this as motivational evidence rather than definitive.

### Concern 8: Mechanism claims not sufficiently separated from reduced-form findings
> "The discussion invokes human capital, signaling, networks, labour market rigidity, and occupational sorting... Those need to be sharply separated."

**Response:** The mechanism discussion (Sections 3.1 and 8) now explicitly labels all mechanism claims as hypotheses for future linked-data work, not findings from the current analysis. Language like "consistent with signaling" is now qualified with "if confirmed by threshold-based estimates."

### Concern 9: Claims and policy implications stronger than evidence warrants
> "The paper does not estimate marginal returns to expanded access, capacity constraints, or completion."

**Response:** Policy implications in Section 8.2 have been softened. The paper now states that the descriptive patterns are "consistent with" large returns to post-school credentials but that marginal returns for newly eligible students remain unknown without causal evidence.

### Concern 10: Title/abstract should match actual evidence
> "Emphasize institutional setting + descriptive gradients + agenda for causal work."

**Response:** Done. Title changed, abstract rewritten, conclusion restructured as two explicit contributions.

---

## Reviewer 3 (Gemini): MAJOR REVISION

### Concern 1: Paper feels like a "pre-analysis plan" attached to a "descriptive report"
> "To reach a top-tier journal, the author likely must actually obtain and run the RDD on the DataFirst microdata. Without the actual RDD estimates, the paper is a high-quality descriptive note, not a flagship causal piece."

**Response:** We accept this characterization. The paper is now explicitly framed as a descriptive documentation paper with an RDD blueprint, not a flagship causal piece. The conclusion presents two distinct contributions accordingly. We agree that the full causal paper requires DataFirst microdata, and the blueprint is designed to facilitate that future work.

### Concern 2: The funding confounder (NSFAS)
> "Explicitly address the role of financial aid (NSFAS). In South Africa, the Bachelor's pass is often the 'key' to government funding. If crossing the threshold provides money, the employment return is not just about the signal or the education, but about the removal of a credit constraint."

**Response:** A discussion of NSFAS has been added to the conceptual framework (Section 3). The paper now notes that crossing the Bachelor's threshold often triggers eligibility for national student financial aid, creating a credit-constraint channel distinct from both signaling and human capital accumulation. This is flagged as a critical confounder that the future RDD must disentangle, potentially by examining differential effects for students above and below NSFAS means-testing thresholds.

### Concern 3: Selection on re-marking
> "Investigate the institutional rules for re-marking. If only wealthy students re-mark their 48% or 49% scores, the 'randomness' of the threshold is compromised."

**Response:** A discussion of re-marking has been added to the institutional background (Section 2). The paper now notes that students may apply for re-marks of individual subjects, that this is more common among wealthier students near threshold scores, and that this could introduce non-random sorting at the cutoffs. McCrary density tests and heterogeneity by school socioeconomic status are flagged as essential validity checks for the future RDD.

### Concern 4: Heterogeneity by subject
> "The 'binding constraint' might matter differently if it's Mathematics vs. a home language."

**Response:** This is noted as a valuable extension for the microdata analysis but cannot be addressed with the aggregate data currently available. The RDD blueprint section now lists subject-specific heterogeneity as a priority analysis.

### Concern 5: Oster bounds are a sophisticated validation attempt
> "Finding a delta of 3.2 is a strong result."

**Response:** We appreciate this positive assessment. The Oster bounds are now better documented with the underlying values (unconditional gap 20 pp, R-squared = 0.05; controlled gap 15 pp, R-squared = 0.20) to make the result transparent and auditable, while still characterizing it as suggestive rather than decisive (per R1 and R2's concerns).

### Concern 6: COVID section is a highlight
> "Using the pandemic as a shock to show that the 'cliff' actually widened provides strong evidence that the credential is not just a signal but potentially a proxy for occupational 'remotability.'"

**Response:** We appreciate this reading. The COVID section is retained but reframed as a descriptive extension about heterogeneity in macro shocks (per R1's concern), rather than as a robustness test for the threshold mechanism.

---

## Summary of All Changes

| Change | Location | Responding to |
|--------|----------|---------------|
| Title recalibrated | Title page | R1-11, R2-10 |
| ~30 causal language edits | Throughout | R1-6/11, R2-1/10 |
| SEs for key differences | Tables 2, 3; abstract | R1-3, R2-3 |
| NSFAS funding discussion | Section 3 (conceptual framework) | R3-2 |
| Re-marking discussion | Section 2 (institutional background) | R3-3 |
| Oster bounds documented | Section 7.4 | R1-5, R2-4 |
| Conclusion rewritten | Section 8 | R1-1, R2-1, R3-1 |
| SDE table corrected | Appendix | Internal QC |
| Roadmap paragraph shortened | Section 1 | Prose review |
| Province extrapolation removed | Section 7.3 | R2-6 |
| COVID section reframed | Section 7.2 | R1-9 |
| Cross-country claims toned down | Section 6 | R1-10, R2-9 |
| Sharp vs fuzzy distinction | Section 5 | R2-2 |
| Causal chain made explicit | Section 3 | R1-4, R2-7 |
