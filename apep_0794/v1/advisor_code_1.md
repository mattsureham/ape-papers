# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-23T11:05:14.896349

---

**Idea Fidelity**

The paper adheres closely to the manifest. It uses the IPEDS universe, compares the 1,084 test-required institutions before/after COVID with continuous treatment intensity given by pre-pandemic SAT 25th percentile scores, and focuses on racial enrollment shares along with admissions outcomes. The identification strategy (within-treated intensity DiD, placebo on pre-existing test-optional schools) and research question from the manifest are fully pursued. The primary divergence is the framing: the paper emphasizes the “application illusion” narrative and places more weight on the modest Black-share gradient than the original idea statement did. Overall, the paper faithfully implements the proposed design and data.

**Summary**

The paper studies the COVID-driven shift to test-optional admissions using the full IPEDS universe of four-year institutions. It documents a large increase in applications to formerly test-required schools but only tiny changes in enrollment composition, and it pinpoints a small positive “intensity” effect on Black enrollment share at institutions with higher pre-COVID SAT 25th percentiles. The take-away is that removing standardized-test mandates eased application barriers without meaningfully altering who enrolled, suggesting tighter constraints upstream.

**Essential Points**

1. **Credibility of the intensity identification.** The core claim relies on the assumption that, within test-required institutions, there would have been no differential enrollment trends by pre-COVID SAT selectivity absent the test-optional shock. Although the paper reports flat pre-trends in the intensity event study, this evidence is relegated to an appendix and described only qualitatively. A more transparent presentation (e.g., a figure with confidence bands, or reporting the underlying coefficients numerically in the main text) is required to give readers confidence that the identifying assumption holds. In particular, the marginally significant coefficient at event time −6 requires discussion regarding whether it reflects noise, sorting, or early divergence.

2. **Interpretation of the small estimated effect.** The preferred estimate (+0.29 pp per SD) is statistically significant but economically tiny, and the paper already hedges that it is “small positive.” The sooner the manuscript confronts the possibility that this may be a statistical artifact (especially when adding state×year FE or enrollment weights) and discusses to what extent it can rule out near-zero effects, the better. More formal estimation of bounds (e.g., by reporting confidence intervals for effect sizes scaled to the treated distribution) or a sensitivity analysis would clarify whether the estimate is robust to plausible alternative specifications. Without this, the policy conclusion—that tests were not binding barriers—is exposed to the charge that the data are simply too noisy to detect even moderate effects.

3. **Mechanisms and COVID confounds.** The intensity specification may still capture other changes correlated with selectivity (say, higher-selectivity schools responding differently to recruitment disruptions or financial aid shocks). The paper notes this risk and includes state×year FE, but the robustness is limited. Adding institution-specific trends, allowing for flexible cohort effects, or exploiting heterogeneity in the timing of re-adoption of test requirements (the 100 that reverted to test-required after 2020) could strengthen the causal argument. In its current form, it is difficult to disentangle the test-optional effect from contemporaneous shocks that differentially affected selective institutions (e.g., enrollment-at-risk students deferring or switching plans during the pandemic).

Because the paper’s entire empirical contribution rests on this design, a failure to convincingly address these issues would warrant rejection. However, if the authors can provide the requested evidence and clarity, the paper would meet the standards of AER: Insights.

**Suggestions**

1. **Strengthen presentation of pre-trends.** Bring the intensity event study (coefficients and standard errors) into the main text, ideally as a figure with confidence bands for each relative year. This makes it easier for readers to verify the identifying assumption. In addition, consider showing the placebo event study for the already-test-optional sample in the same format. Annotate the (−6) coefficient and explain why it is not worrisome (e.g., robustness to trimming, whether it disappears when controlling for additional lags).

2. **Expand placebo and heterogeneity analyses.** The placebo on pre-existing test-optional schools is helpful, but additional robustness exercises would bolster credibility. For instance:
   - Run the intensity specification on narrower subsets (e.g., private only, public only) to show that the effect is not driven by one sector.
   - Use alternative measures of selectivity (e.g., SAT 75th percentile, admit rate) to show that results are not specific to the 25th percentile.
   - Conduct falsification tests using outcomes that should not respond to test-optional status (e.g., retention rates, non-racial enrollment categories) to further validate the specification.

3. **Clarify interpretation of enrollment stock.** The paper acknowledges that stock enrollment underestimates flow effects, but it would be helpful to translate this into a more formal decomposition. Could the authors estimate the fraction of the 2023 enrolled body that entered under test-optional admissions (perhaps using cohort progression or first-time freshman counts where available)? If the post-treatment cohorts are undercounted, a simple back-of-the-envelope adjustment could demonstrate that even if the flow effect were twice the estimated stock effect, it would still be small. This would help preempt critiques that the negligible effect is merely a mechanical artifact of measuring the entire undergraduate population.

4. **Deepen the discussion of mechanisms.** The “application illusion” narrative is compelling, but the policy implications would be stronger if the paper more systematically explored upstream barriers. Incorporating auxiliary evidence—such as how Pell shares or net price changed by intensity, or whether the increased application volume was concentrated among non-URM students—would indicate whether the marginal applicants differed demographically. If possible, use IPEDS financial aid data to show whether financial barriers (net price, Pell share) shifted in ways consistent with the argument that enrollment remained constrained upstream.

5. **Improve clarity on the control group.** The binary DiD is undermined by pre-trends, but the data comparison still appears in the results. Consider revising the narrative to make explicit that the binary estimates are illustrative (showing the application surge) rather than causal for enrollment shares. There is also a need to explain why the intensity coefficient is not meaningfully distinguished from zero in the triple-difference; readers might otherwise interpret that as a sign the intensity variation is capturing noise. Presenting confidence intervals or discussing statistical power would help.

6. **Discuss general equilibrium or market reallocation effects.** If the removal of tests simply shifted marginal applicants across institutions, it would be informative to explore whether underrepresented students reallocated from less-selective to more-selective schools or vice versa. The paper mentions total aggregate enrollment in the discussion but doesn’t directly test for compositional shifts across the entire sample. Including a simple calculation (e.g., summing URM counts across treated institutions to see if aggregate numbers changed relative to controls) would illuminate whether there was even a redistribution of students.

Addressing these suggestions would enhance the paper’s rigor and help readers appreciate both the limitations and contributions of this important empirical exercise.
