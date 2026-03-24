# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant A)

**Model:** deepseek/deepseek-v3.2
**Variant:** A
**Date:** 2026-03-13T17:31:59.011633

---

**Referee Report: “The Hidden Wage Floor: How Salary History Bans Reshape Gender Pay Gaps Across Industries”**

**1. Idea Fidelity**

The paper largely pursues the original research idea but deviates from the proposed identification strategy and data use in several critical ways, weakening its credibility and scope.

*   **Data Aggregation:** The original manifest specified using **county-level** QWI data, which would allow for powerful within-state, cross-border county-pair analyses and finer-grained geographic controls. The paper aggregates to the **state-industry** level, losing this valuable source of identification and making the design more vulnerable to state-level confounders. The promised border county robustness check is absent.
*   **Demographic Breakdowns:** The manifest planned to exploit the sex-by-age, sex-by-education, and race-by-ethnicity QWI panels. The paper uses the sex-by-age panel for its main analysis but does not utilize the sex-by-education dimension to test mechanisms (e.g., is the effect stronger for more educated workers where negotiation matters more?). The race analysis is presented but appears as a secondary, less-developed robustness check rather than a core, pre-specified heterogeneity test as framed in the original idea (the “Doleac-Hansen-style” test).
*   **Industry Decomposition:** While the paper examines industry heterogeneity, the simple binary split (high-gap vs. low-gap) based on a 20% threshold, though motivated by pre-ban gaps, is somewhat arbitrary. The original idea implied a richer exploration across the 20 NAICS sectors. The mechanism linking this split to the theory of statistical discrimination vs. anchoring needs stronger justification.

In summary, the paper captures the core question and uses staggered DiD, but it employs a less rigorous empirical implementation (state-level aggregation) and a less comprehensive exploration of the proposed demographic and industry heterogeneity than originally outlined.

**2. Summary**

This paper provides novel evidence that state-level salary history bans have heterogeneous effects on gender pay gaps, compressing them in industries with historically large gaps (e.g., finance, healthcare) but widening them in industries with historically smaller gaps (e.g., manufacturing, wholesale). The authors interpret this pattern through the lens of statistical discrimination, whereby removing an informative signal (prior salary) leads employers to rely more on group-level priors, helping women where those priors were biased downward and hurting them where prior salaries were relatively equitable.

**3. Essential Points (Must Address)**

The following issues are critical and must be convincingly addressed for the paper to be publishable.

**1. The State-Level Aggregation Undermines the Identification Strategy.**
The decision to aggregate QWI data to the state-industry level is a major weakness. It throws away the county-level variation that is central to a credible staggered DiD design in this context. State-level policies are often correlated with other state-level trends (e.g., minimum wage laws, paid leave policies, general political climate affecting discrimination). The original plan to use county-level data with state-time and industry-time fixed effects is vastly superior. The authors must re-estimate their core models using **county-industry-level data**. This would allow for the inclusion of state-by-quarter fixed effects, which would absorb *all* state-specific shocks over time—a crucial control given the potential for concurrent policies. Failing to do so leaves the estimates vulnerable to omitted variable bias. The promised “border county pairs” robustness check cannot be performed with state-level data and should be a core part of the re-analysis.

**2. The Treatment Effect Heterogeneity is Insufficiently Justified and Tested.**
The binary “HighGap” classification is the linchpin of the story but is under-theorized and mechanically driven.
    *   **Threshold Justification:** Why 20%? The paper needs a stronger, pre-analysis justification for this cutoff, perhaps based on the distribution of gaps or external evidence. A sensitivity analysis using alternative thresholds (e.g., median split, terciles) or a continuous interaction with the pre-ban gap level should be presented to show the result is not an artifact of this specific binary choice.
    *   **Direct Mechanism Evidence:** The statistical discrimination narrative is plausible but indirect. The authors must provide more direct evidence to distinguish it from alternative explanations (e.g., differential compliance, changes in job posting language, shifts in occupational mix within industries). Can they find supplementary data (e.g., from Burning Glass/Lightcast on job postings) to show that the *removal of salary history questions* indeed occurred differentially or that employers substituted with other signals (like education or certification requirements)? A simple placebo test on older men is not enough. The “race heterogeneity” result is suggestive but underdeveloped (see point 3).

**3. The Analysis of Race and Intersectionality is Preliminary and Lacks Causal Identification.**
The race results are presented as a robustness check but are central to the Doleac-Hansen parallel the authors wish to draw. In its current form, this analysis is not credible.
    *   **Lacks a Clear Design:** The race analysis appears to be a simple DiD comparing Black vs. White workers, not the triple-difference (state x race x post) or quadruple-difference (adding industry type) needed to isolate the policy effect. The estimates in Table 4, Panel D, are likely confounded by overall state-time trends.
    *   **Needs Intersectional Focus:** The most policy-relevant question is how the ban affected *Black women* or *Hispanic women* relative to other groups. The current analysis pools across genders, muddying the interpretation. The authors should implement a proper DDD or DDDD design (e.g., state x post x race x gender, or state x post x industry-gap-type x race) using the QWI race-by-ethnicity panel to credibly estimate these heterogeneous effects.

**4. Suggestions for Improvement**

*   **Empirical Specification & Robustness:**
    *   **Implement County-Level Analysis:** Re-run all analyses at the county-industry level. Include **state-by-quarter fixed effects** to absorb all state-specific shocks. Cluster standard errors at the state level (or use two-way clustering by state and industry-quarter if feasible).
    *   **Formal Event Study:** Present a fully dynamic event study graph for the key triple-difference coefficient (Female x Post x HighGap) to visually assess pre-trends in the *heterogeneity*, not just in the aggregate gender gap. This is a stricter test of the identifying assumption.
    *   **Sun & Abraham/Stacked Estimators:** Given the staggered adoption, explicitly use the Sun & Abraham (2020) estimator or a stacked regression estimator as a robustness check to ensure the results are not driven by heterogeneous treatment effects or the “forbidden comparison” between early- and late-treated units.
    *   **Border County Design:** As originally proposed, implement a border county-pair design as a strong falsification test, comparing counties in treated states to adjacent counties in untreated states within the same industry and quarter.

*   **Mechanisms & Heterogeneity:**
    *   **Refine Industry Analysis:** Move beyond the binary split. Show the interaction effect (Female x Post) for *each* of the 20 NAICS sectors in a coefficient plot. This would visually demonstrate the gradient of effects and validate (or complicate) the binary story.
    *   **Explore Other Demographics:** Use the sex-by-education QWI panel to test if effects are concentrated among college-educated workers, for whom salary history might be a more salient anchor.
    *   **Hiring vs. Wages:** The paper finds suggestive hiring effects. Dive deeper into the hiring margin. Does the gender composition of new hires change? If statistical discrimination is at play in low-gap industries, do we see a relative decline in female hiring rates there?

*   **Interpretation & Context:**
    *   **Engage with Conflicting Literature:** Directly discuss why the findings might differ from Agan & Starr (2022) or others. Is it due to the industry disaggregation, the focus on new hires, or data source differences?
    *   **Clarify the Policy Implication:** The conclusion that effects depend on “where workers are” is important. Elaborate on the welfare implications. If the policy helps women in finance but hurts women in manufacturing, what is the net effect, and how should policymakers weigh this? Discuss the potential for complementary policies (like pay range transparency) to mitigate the negative effects in low-gap industries.
    *   **Strengthen the Link to Theory:** More formally lay out the simple theoretical framework in the background section: under what conditions (accuracy of group priors vs. information content of salary history) does removing the signal help or hurt the disadvantaged group? This will sharpen the interpretation of the industry heterogeneity.

*   **Presentation:**
    *   **Table 1 (Summary Stats):** Include a column showing the number of observations or counties for each group. The “N” listed seems to be state-industry-sex-quarters; clarify.
    *   **Table 2 (Pre-Gap):** List all 20 industries, not just 12, to be transparent about the full classification.
    *   **Discuss Sample Size:** The paper notes 101,293 observations. Confirm this aligns with state (50) x industry (20) x sex (2) x quarters (~50) and explain any exclusions (e.g., territories, suppressed data).

The paper tackles a timely question with a novel angle on heterogeneity. The core idea is strong, but the current execution does not meet the evidentiary standard required for a causal claim in a top journal. Addressing the essential points—particularly moving to a county-level design with tighter controls and fortifying the mechanism and race analyses—would significantly elevate its contribution.
