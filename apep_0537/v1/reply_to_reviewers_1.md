# Reply to Reviewers

## Reviewer 1 (GPT-R1): REJECT AND RESUBMIT

### Must-Fix Issues Addressed

**1. Reframe away from causal claims about generative AI**
- **Response:** We agree this is the central issue. The paper's own event study and placebo analysis demonstrate that parallel trends fail. We have added the industry-specific linear trends specification (R9), which confirms that the main DiD result reverses sign once secular industry trends are absorbed. The paper's contribution is now framed as documenting a long-run descriptive association between AI task exposure and seniority composition, not as causal evidence of a generative AI effect. The discussion and conclusion have been revised accordingly.

**2. Re-estimate within-industry models with appropriate FE**
- **Response:** We acknowledge the concern about industry × year FE for the DDD. With 25 industries × 10 years × 3 seniority groups = 750 obs and 250 industry-year cells, adding industry × year FE absorbs most variation. We discuss this power limitation explicitly but agree the current DDD null is uninformative given the specification limitations.

**3. Address inference with few clusters**
- **Response:** We have added permutation inference (999 permutations, reassigning AIOE across industries). The permutation p-values closely track conventional cluster-robust p-values (0.095 vs 0.104 for continuous, 0.044 vs 0.045 for binary, 0.002 vs 0.008 for senior share), confirming that small-cluster inference is not artificially inflating significance.

**4. Add pre-trend diagnostics for heterogeneity specification**
- **Response:** We add a formal joint F-test for pre-period event study coefficients (F = 2.61, p = 0.013), confirming that parallel trends are violated. We acknowledge that the heterogeneity specification lacks its own event study and state this limitation explicitly.

**5. Add industry-specific trend specifications**
- **Response:** Done. With industry-specific linear trends, the entry-share coefficient reverses sign to +0.009 (t = 3.45) and the senior-share coefficient becomes insignificant (+0.004, t = 1.06). This confirms the DiD results are driven by pre-existing trends. This is now the most important robustness check in the paper.

### High-Value Improvements
- **Weighting:** We clarify that regressions are unweighted at the industry level (consistent with treating each industry as a unit of analysis).
- **Alternative explanations:** We discuss these qualitatively but acknowledge the need for empirical controls, listed as a limitation.
- **Claim calibration:** We have softened language throughout, including the abstract and policy implications.

---

## Reviewer 2 (GPT-R2): MAJOR REVISION

### Key Concerns Addressed

**1. Reframe away from causal claims**
- **Response:** Same as R1 response above. The paper now frames results as descriptive associations.

**2. Strengthen inference**
- **Response:** Permutation inference added (see R1 response). Results confirm conventional p-values are reliable.

**3. Validate heterogeneity specification**
- **Response:** We add the joint F-test for pre-trends. We acknowledge that the heterogeneity specification lacks its own event study, stated as a key limitation.

**4. Clarify weighting**
- **Response:** Added explicit statement that regressions are unweighted at the industry level.

**5. Temper job-count conversions**
- **Response:** We add qualifying language to make clear these are arithmetic decompositions of descriptive magnitudes, not causal treatment effects.

**6. Industry-specific trends**
- **Response:** Done (see R1).

**7. Missing literature**
- **Response:** Added Cameron, Gelbach, and Miller (2008) for cluster inference. We discuss the relevance of Roth (2022) and Rambachan-Roth (2023) in the pre-trends context.

---

## Reviewer 3 (Gemini): MINOR REVISION

**1. Wild Cluster Bootstrap**
- **Response:** fwildclusterboot is unavailable for our R version. Instead, we provide permutation inference (999 reassignments), which addresses the same concern about small-cluster inference reliability. Results are highly consistent with conventional p-values.

**2. Age/Education Controls**
- **Response:** We discuss this as a limitation. Adding time-varying industry controls from CPS/ACS would require matching at a granularity that may introduce its own measurement error given NAICS coding differences.

**3. O*NET Job Zone vs. experience**
- **Response:** We acknowledge this limitation (Job Zones capture preparation requirements, not tenure). Testing with alternative seniority measures is noted as an avenue for future work.
