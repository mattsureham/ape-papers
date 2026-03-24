# V1 Empirics Check — mistralai/mistral-large-2512 (Variant A)

**Model:** mistralai/mistral-large-2512
**Variant:** A
**Date:** 2026-03-23T11:06:42.200962

---

### 1. Idea Fidelity

The paper closely adheres to the original idea manifest. It successfully executes the proposed identification strategy—using pre-COVID SAT 25th percentile as a continuous treatment intensity in a difference-in-differences (DiD) framework—to estimate the causal effect of test-optional admissions on racial and socioeconomic composition of college enrollment. The key elements of the manifest are preserved:

- **Data source**: The paper uses the IPEDS universe (2014–2023) as proposed, covering 1,084 treated institutions (test-required in 2019) and ~900 controls (already test-optional).
- **Identification strategy**: The continuous treatment intensity DiD is implemented as described, with pre-trends and placebo tests to validate the design. The paper also includes a binary DiD as a secondary specification.
- **Outcomes**: The primary outcomes (Black, Hispanic, and URM enrollment shares) and secondary outcomes (admission rates, yield, applications) match the manifest.
- **Novelty**: The paper delivers on its promise of providing the first institution-universe evidence on test-optional admissions, distinguishing itself from prior work using proprietary data (e.g., Common App).

The paper does not miss any critical elements of the manifest. However, it could have more explicitly addressed the socioeconomic outcomes (e.g., Pell Grant shares) mentioned in the manifest, which are relegated to the appendix or omitted entirely. This is a minor deviation but worth noting.

---

### 2. Summary

This paper exploits the COVID-induced shift to test-optional admissions as a natural experiment to study its effects on the racial composition of college enrollment. Using the complete IPEDS universe of U.S. institutions, the authors find that while applications to formerly test-requiring schools surged by 14.3%, the racial composition of enrolled students barely changed. A continuous treatment intensity design—leveraging pre-COVID SAT selectivity—shows that a one-standard-deviation increase in selectivity raised Black enrollment share by just 0.29 percentage points (2% of the pre-treatment mean). The results suggest that standardized tests were not a primary barrier to diversity, as their removal had minimal effects on enrollment composition. The paper contributes novel, system-wide evidence to the debate on test-optional admissions and highlights the distinction between application and enrollment barriers.

---

### 3. Essential Points

The paper is methodologically sound and makes a valuable contribution, but three critical issues must be addressed before publication:

#### (1) **Clarify the interpretation of the binary DiD results**
The binary DiD specification (Table 1) shows a statistically significant *decline* in Black enrollment share at treated institutions relative to controls, but the event study reveals problematic pre-trends (treated institutions were already diversifying faster than controls pre-2020). The authors rightly dismiss the binary DiD as unreliable but should explicitly state that this specification is included only for completeness and is not a valid causal estimate. The text should clarify that the intensity design is the preferred specification and that the binary DiD’s negative coefficient is likely driven by pre-existing trends, not the policy change.

#### (2) **Address potential confounding from COVID-19 disruptions**
The test-optional transition coincided with other COVID-related disruptions (e.g., campus closures, financial aid changes, shifts in student mobility). While the intensity design and placebo tests mitigate some concerns, the authors should more explicitly discuss how these confounders might bias the results. For example:
   - Did institutions with higher SAT selectivity also experience larger enrollment declines during COVID? If so, the intensity gradient could reflect differential enrollment shocks rather than the test-optional policy.
   - The paper includes state-by-year fixed effects as a robustness check, but the text should explain why this is sufficient to address state-level confounders (e.g., state financial aid policies, K-12 disruptions).
   - The authors should discuss whether the gradual emergence of effects in the event study (2021–2023) could reflect delayed COVID effects (e.g., financial aid appeals, deferrals) rather than the test-optional policy.

#### (3) **Reconcile the small effect size with the paper’s framing**
The paper’s abstract and introduction frame the results as a "striking disconnect" between applications and enrollment, but the effect on Black enrollment share is economically negligible (0.29 pp, or 2% of the pre-treatment mean). While the authors acknowledge this in the discussion, the framing should be toned down to avoid overstating the policy’s impact. Specifically:
   - The abstract should explicitly state that the effect on enrollment composition is "economically small" rather than implying a meaningful disconnect.
   - The introduction should clarify that the "application illusion" refers to the *magnitude* of the effect (large application surge, tiny enrollment effect) rather than suggesting the policy failed entirely. The results are still important—they show that tests were not a binding barrier—but the framing should align with the effect size.

---

### 4. Suggestions

#### (1) **Improve the discussion of mechanisms**
The paper argues that the binding constraints on diversity lie "upstream" of admissions (e.g., K-12 preparation, financial aid, information frictions), but it does not test these mechanisms directly. To strengthen this claim, the authors could:
   - Add a table or figure showing heterogeneity by institutional characteristics that proxy for upstream barriers. For example:
     - **Financial aid generosity**: Do institutions with higher Pell Grant shares or lower net prices show larger effects? If not, this would support the argument that financial barriers are binding.
     - **High school pipelines**: Do institutions with more feeder high schools in majority-minority districts show larger effects? This could test whether information frictions are a constraint.
   - Discuss whether the lack of effect on Hispanic enrollment (despite a large test score gap) reflects different upstream barriers for Hispanic students (e.g., immigration status, language barriers) or measurement issues (e.g., Hispanic students being more likely to attend Hispanic-Serving Institutions, which were already test-optional).

#### (2) **Address the stock vs. flow issue more rigorously**
The paper uses total undergraduate enrollment (stock) rather than first-time freshman enrollment (flow), which attenuates the estimated effect. The authors acknowledge this limitation but could:
   - Provide a back-of-the-envelope calculation of the implied flow effect. For example, if 60% of enrolled students in 2023 were admitted under test-optional policies, the true flow effect might be ~1.67× larger (0.29 pp × 1.67 ≈ 0.48 pp). This would still be small but would help readers contextualize the magnitude.
   - Discuss whether the gradual emergence of effects in the event study (2021–2023) is consistent with the stock-flow dynamic. For example, if the effect on entering cohorts is larger, the event study coefficients should increase over time, which they do (0.10 pp in 2020 → 0.37 pp in 2021).

#### (3) **Expand the robustness checks**
The paper includes several robustness checks (state-by-year FE, enrollment weighting, placebo tests), but additional tests could further validate the results:
   - **Alternative treatment intensity measures**: The SAT 25th percentile is a reasonable proxy for test reliance, but other measures could be tested, such as:
     - The gap between the SAT 25th and 75th percentiles (a proxy for how much institutions rely on test scores for screening).
     - The share of applicants submitting test scores pre-COVID (if available in IPEDS).
   - **Alternative control groups**: The placebo test uses already-test-optional institutions as controls, but these may differ systematically from treated institutions. The authors could:
     - Use a synthetic control approach to construct a more comparable control group from test-required institutions that were "close" to going test-optional pre-COVID.
     - Restrict the control group to institutions that were test-recommended (not test-optional) in 2019, as these may be more similar to treated institutions.
   - **Dynamic effects**: The event study shows gradual effects, but the main results pool post-2020 years. The authors could report separate coefficients for 2020, 2021, 2022, and 2023 to show how the effect evolves over time.

#### (4) **Improve the presentation of results**
- **Table 1 (binary DiD)**: The table should include a note explicitly stating that the binary DiD is unreliable due to pre-trends and is included only for completeness. The event study figure should be referenced in the table note.
- **Table 2 (intensity results)**: The table should include a column with the unstandardized SAT 25th percentile (not just the standardized intensity) to help readers interpret the magnitude. For example, a one-SD increase in SAT 25th percentile corresponds to ~119 points, so the effect of 0.29 pp per SD is ~0.0024 pp per SAT point.
- **Figure 1 (event study)**: The event study figure is critical but is not included in the LaTeX source. The authors should add a figure showing the event study coefficients for both the binary and intensity specifications, with 95% confidence intervals and a vertical line at 2020. This would help readers visualize the pre-trends and gradual effects.
- **Standardized effect sizes**: The appendix includes a table of standardized effect sizes (Table A4), but this should be moved to the main text (e.g., as Table 3) to help readers assess the economic significance of the results.

#### (5) **Clarify the policy implications**
The paper’s conclusion—that the binding constraints lie upstream of admissions—is important but could be sharpened:
   - **For policymakers**: The results suggest that test-optional policies alone are insufficient to diversify enrollment. The authors should discuss what *would* work, such as:
     - Targeted outreach to high-minority high schools (e.g., Hoxby and Avery’s "Expanding College Opportunities" intervention).
     - Financial aid reforms (e.g., simplifying the FAFSA, expanding Pell Grants).
     - K-12 reforms to close preparation gaps (e.g., advanced coursework access, test prep resources).
   - **For institutions**: The paper shows that test-optional policies increase applications but not enrollment diversity. Institutions should pair test-optional policies with other efforts, such as:
     - Holistic review practices that account for structural barriers (e.g., adversity indices).
     - Yield initiatives to convert admitted minority students (e.g., fly-in programs, targeted aid packages).
   - **For researchers**: The paper highlights the need for more research on the "bottom of the funnel" (enrollment decisions) rather than the "top of the funnel" (applications). Future work could:
     - Use student-level data to track how test-optional policies affect individual application and enrollment decisions.
     - Study whether test-optional policies interact with other admissions criteria (e.g., essays, extracurriculars) to perpetuate inequality.

#### (6) **Address omitted outcomes**
The manifest mentions socioeconomic outcomes (e.g., Pell Grant shares, net price by income quintile), but these are not reported in the main text. The authors should:
   - Add a table or appendix table showing results for Pell Grant shares and net price by income quintile, using the same intensity specification.
   - Discuss whether the lack of effect on racial composition extends to socioeconomic composition. If so, this would further support the argument that the binding constraints are upstream.

#### (7) **Improve the discussion of external validity**
The paper’s results are based on the COVID-induced test-optional transition, which was sudden and universal. The authors should discuss whether the results generalize to:
   - **Voluntary test-optional policies**: Institutions that choose to go test-optional may differ from those forced to do so (e.g., they may have stronger diversity goals or different applicant pools). The authors could compare their results to those of prior studies using voluntary adopters (e.g., Bennett 2022, Dynarski 2023).
   - **Test-blind policies**: The paper focuses on test-optional policies, but some institutions are test-blind (they do not consider test scores even if submitted). The authors could discuss whether test-blind policies might have larger effects, as they remove the signaling value of test scores entirely.

#### (8) **Minor suggestions**
- **Abstract**: The abstract should mention that the effect on Black enrollment share is economically small (e.g., "a modest 0.29 percentage point increase").
- **Introduction**: The introduction should clarify that the paper’s contribution is *system-wide* evidence, not just another study of selective institutions. The authors could contrast their results with prior work using proprietary data (e.g., Common App) to highlight the value of the IPEDS universe.
- **Data section**: The data section should include a table or figure showing the distribution of SAT 25th percentiles among treated institutions to help readers understand the treatment intensity variation.
- **Discussion**: The discussion should explicitly state that the results do not imply that standardized tests are *unimportant*—only that they are not the primary barrier to diversity. The authors could cite Chetty et al. (2023) to acknowledge that tests predict success but may not be the binding constraint for enrollment.

---

### Final Assessment

This is a strong paper that makes a novel and policy-relevant contribution. The identification strategy is credible, the data are comprehensive, and the results are clearly presented. With the revisions suggested above—particularly clarifying the interpretation of the binary DiD, addressing COVID confounders, and toning down the framing—the paper would be suitable for publication in a top field journal like *AER: Insights*. The authors have done an excellent job of executing the original idea, and the paper’s findings will be of broad interest to economists, policymakers, and higher education researchers.
