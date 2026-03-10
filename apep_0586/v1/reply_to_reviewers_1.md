# Reply to Reviewers

## Response to GPT-5.4 Reviewer 1 (R1)

### §1A. Paper's strongest result is rejection of its own identifying assumption

**Response:** We agree completely and have reframed the paper accordingly. The title now reads "How a Third Census Decade Exposes Identification Failure in WWII Service-Return Estimates." The abstract leads with the falsification test rather than causal claims. The introduction explicitly states the contribution is "primarily methodological." The conclusion reframes the finding as diagnostic.

### §1B. Exclusion not credible for military-service interpretation

**Response:** We agree that the mobilization instrument bundles many state-level characteristics beyond veteran service intensity. We have added a detailed estimand discussion (Section 5.1, "A note on the estimand") explicitly stating that β₁ captures the composite effect of "mobilization exposure" rather than military service per se. The new Discussion Section 8.1 ("What Does the Design Identify?") provides a full treatment of what the instrument can and cannot isolate. Throughout the paper, we now interpret the coefficient as the effect of "mobilization exposure" rather than "military service."

### §1C. Control group contamination

**Response:** We have added a new limitation paragraph (Section 8.5, third paragraph) discussing the nonzero service probability of the older control cohort. We note that alternative control cohorts yield qualitatively similar results but with wider confidence intervals.

### Trend-adjusted specification

**Response:** We have demoted the trend-adjusted specification from a preferred corrected estimate to an "Exploratory" exercise (Section 5.3 now titled "Trend-Adjusted Estimates (Exploratory)"). The text explicitly states we "present this specification as illustrative rather than as a preferred corrected estimate" and acknowledges the linearity assumption cannot be fully justified.

---

## Response to GPT-5.4 Reviewer 2 (R2)

### Must-Fix 1: Reframe the causal claim

**Response:** Done comprehensively. Title, abstract, introduction, and conclusion all reframed around the diagnostic/methodological contribution. The abstract no longer claims "career disruption from military service." The introduction explicitly states the contribution is "primarily methodological" and adds a note on the estimand. The conclusion opens with "A third decade of census data transforms the evaluation of a widely used identification strategy" rather than claiming to estimate service returns.

### Must-Fix 2: Justify or demote trend-adjusted specification

**Response:** Demoted. Section 5.3 retitled "Trend-Adjusted Estimates (Exploratory)." Text now says "illustrative rather than preferred corrected estimate." Added explicit caveats about linearity assumption and different lifecycle margins. Discussion (Section 8.1) treats it as "indicative of bias direction rather than as a point estimate."

### Must-Fix 3: Strengthen identification analysis around alternative state-specific cohort trends

**Response:** We have added a new subsection (8.2, "What Would Strengthen Identification?") outlining the specific extensions that would address this concern: (1) interactions of draft eligibility with additional state characteristics (urbanization, income, Depression severity, New Deal spending, education, racial composition); (2) region × cohort fixed effects; (3) within-state variation using county or SEA agricultural shares. We frame these as an explicit agenda for future work rather than claiming to resolve them.

### Must-Fix 4: Evidence on sample selection from three-wave linkage

**Response:** Section 7.5 has been substantially expanded to "Linking Quality and Survivorship Selection." We now distinguish two concerns (linkage selection and survivorship selection), discuss why the pre-trend finding is not subject to survivorship bias (mortality had not yet occurred), and explicitly acknowledge that a full diagnostic requires linking-rate data by state and cohort.

### Must-Fix 5: Clarify role of pre-trend test

**Response:** Section 5.2 retitled "The Falsification Test: The Central Finding." We now explicitly call it a "falsification test rather than a parallel-trends test in the strict difference-in-differences sense" and explain why: the 1930–1940 outcome margin (labor-force entry for teenagers) differs from 1940–1950 (early-career progression). The test asks whether the identifying interaction is correlated with pre-treatment dynamics, not whether the same trend process governs both decades.

### High-Value 6: Improve inference

**Response:** RI section now describes the permutation design precisely (pure label permutation, 49 state-level values reassigned without replacement). We acknowledge that this does not respect geographic/economic structure and that wild-cluster bootstrap (Cameron, Gelbach, and Miller 2008) would be a useful complement. Added the reference.

### High-Value 7: Sample-size reconciliation

**Response:** We note in the pre-trend discussion that pre-trend controls (1930-based) have less missingness than 1940 controls, which accounts for the observation count differences across tables. The 30% subsample and missing-controls sample attrition are documented in Appendix A.

### High-Value 8: Mechanism interpretation

**Response:** Section 6.4 ("Discussion of Mechanisms") substantially rewritten. We now explicitly state "the reduced-form design cannot isolate military service from other state-specific cohort shocks, so we cannot definitively attribute the negative coefficient to any single channel." The college result is reframed: "not necessarily evidence that the GI Bill was ineffective—the instrument may simply be poorly suited to capturing the educational channel." The third mechanism is now "State-level economic dynamics" rather than "Composition effects."

### High-Value 9: Control cohort contamination

**Response:** Added to limitations (Section 8.5, third paragraph).

### Optional 10: Align title

**Response:** Title changed to emphasize identification failure.

### Optional 11: Reduce heterogeneity emphasis

**Response:** Section 6 now opens with explicit caveat that "these exercises are suggestive: the subgroup estimates are often imprecise and not statistically distinguishable from each other."

### Optional 12: Estimand discussion

**Response:** Added as paragraph in Section 5.1 and expanded in Discussion Section 8.1.

---

## Response to Gemini Reviewer

### Must-Fix 1: First-stage transparency

**Response:** Section B.1 (Identification Appendix) now explicitly discusses why we cannot estimate a first stage (lack of individual-level service records; 1950 WWII service question limited to 5% sample). We note that our own pre-trend evidence raises concerns about the exclusion restriction needed for any 2SLS interpretation.

### High-Value 2: Mortality/Attrition selection

**Response:** Section 7.5 substantially expanded to discuss survivorship selection. We note that the pre-trend finding is immune to this concern (no WWII mortality in 1930–1940) and explicitly flag the post-treatment estimates as potentially affected. We acknowledge that a full linking-rate balance check by state × cohort is needed.

### Optional 3: Sub-state variation

**Response:** Mentioned as a priority extension in new Section 8.2 ("What Would Strengthen Identification?").

---

## Summary of Changes

| Area | Change |
|------|--------|
| Title | Reframed to emphasize identification failure |
| Abstract | Leads with falsification test; removes "career disruption" headline |
| Introduction | Contribution framed as "primarily methodological"; adds estimand note; reframes Collins & Zimran comparison |
| Section 5.1 | Added estimand discussion paragraph |
| Section 5.2 | Retitled "Falsification Test"; reframed from parallel-trends to falsification; age-placebo caveat added |
| Section 5.3 | Retitled "(Exploratory)"; demoted from preferred estimate to illustrative |
| Section 6 | Softened mechanism language throughout; explicit reduced-form caveat |
| Section 7.2 | RI design described precisely; wild-cluster bootstrap acknowledged |
| Section 7.5 | Expanded to cover survivorship selection and linkage bias |
| Section 8 | Complete restructure: new subsections on estimand, future identification, and control-group limitations |
| Conclusion | Reframed as diagnostic contribution; avoids claiming causal service returns |
| References | Added Cameron, Gelbach, and Miller (2008) |
