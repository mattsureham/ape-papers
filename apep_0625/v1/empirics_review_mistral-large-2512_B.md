# V1 Empirics Check — mistralai/mistral-large-2512 (Variant B)

**Model:** mistralai/mistral-large-2512
**Variant:** B
**Date:** 2026-03-13T11:15:18.729521

---

### 1. Idea Fidelity

The paper closely adheres to the original idea manifest, successfully executing the core research question: estimating the causal effect of salary history bans on gender and racial earnings gaps using staggered difference-in-differences (DiD) with QWI data. Key elements from the manifest are preserved:
- **Data**: The paper uses the promised QWI county-level data (aggregated to state-industry-quarter) with sex, age, and race breakdowns across 20 industries.
- **Identification**: The Callaway-Sant’Anna staggered DiD is implemented as planned, with triple-difference (DDD) specifications for gender and race heterogeneity. The cross-industry DDD (high- vs. low-gender-gap industries) and Doleac-Hansen-style statistical discrimination tests are included.
- **Outcomes**: New-hire earnings (`EarnHirNS`), hiring rates, and separations are analyzed, with a focus on gender pay compression.
- **Novelty**: The paper delivers on its promise of industry-level decomposition and hiring flow dynamics, filling gaps in the literature.

**Minor deviations**:
- The manifest proposed a *county-level* analysis, but the paper aggregates to *state-industry-quarter* (likely for computational feasibility). This is a reasonable simplification but should be justified.
- The race-by-ethnicity panel is used only for Black-White comparisons, not Hispanic or other groups. The manifest’s broader race heterogeneity test is narrowed, which is acceptable but could be clarified.

---

### 2. Summary

This paper leverages staggered state-level salary history bans (2017–2023) and QWI administrative data to estimate the causal effect of these policies on gender and racial earnings gaps. Using a Callaway-Sant’Anna DiD design, the authors find that bans narrowed the gender earnings gap among new hires by 2.3 log points (8.5% of the pre-ban gap), with effects growing to 4.1 log points after three years. Effects are strongest in healthcare and professional services, and there is no evidence of statistical discrimination against Black workers. The paper highlights the importance of heterogeneity-robust estimators, as standard TWFE yields null results.

---

### 3. Essential Points

**1. Justify the aggregation from county to state-industry-quarter.**
   - The manifest emphasizes county-level variation, but the paper aggregates to state-industry-quarter. This risks losing granularity (e.g., urban/rural heterogeneity) and may violate the stable unit treatment value assumption (SUTVA) if labor markets spill across counties. The authors should:
     - Explicitly state the aggregation choice and its implications.
     - Test robustness to county-level analysis (even if only for a subset of states/industries).
     - Discuss whether state-level clustering of standard errors is sufficient to account for spatial correlation.

**2. Clarify the race heterogeneity analysis.**
   - The manifest proposes testing for Doleac-Hansen-style statistical discrimination across race *and* ethnicity, but the paper focuses only on Black-White gaps. The authors should:
     - Justify the exclusion of Hispanic and other racial groups (e.g., data limitations, power).
     - Report results for Hispanic workers in an appendix if sample sizes are small.
     - Address whether the lack of statistical discrimination against Black workers generalizes to other groups.

**3. Strengthen the mechanism tests.**
   - The industry heterogeneity results (Table 4) are underpowered and inconclusive. The triple-difference (DDD) specification (Post × Ban × High-Gap Industry) is not reported in the table, and the industry-specific effects are noisy. The authors should:
     - Report the DDD interaction term explicitly (even if insignificant).
     - Test whether the effect is larger in industries with higher pre-ban gender gaps using a continuous measure (e.g., pre-ban gap size) rather than a binary split.
     - Discuss why high-gap industries like Arts & Entertainment show no effect (e.g., structural barriers beyond anchoring).

---

### 4. Suggestions

#### **Conceptual and Theoretical**
1. **Refine the anchoring vs. information-loss framing.**
   - The paper argues that bans work by removing wage anchors, but the information-loss channel (statistical discrimination) is only briefly addressed. The authors should:
     - Explicitly model the trade-off between anchoring and information loss in the introduction.
     - Discuss why salary history bans might differ from ban-the-box (e.g., salary history is less correlated with race than criminal records).
     - Highlight the absence of statistical discrimination as a key finding, not just a robustness check.

2. **Expand the discussion of general equilibrium effects.**
   - The paper finds that male earnings rise modestly post-ban (Table 5, Column 4). This suggests firms may adjust overall compensation structures, not just female wages. The authors should:
     - Speculate on why male earnings increase (e.g., firms raise wages to attract talent in a tighter labor market).
     - Test whether the effect on male earnings varies by industry or state labor market conditions.

3. **Address potential spillovers.**
   - If firms in ban states hire workers from non-ban states, or if multi-state firms standardize policies, SUTVA may be violated. The authors should:
     - Discuss whether spillovers are likely (e.g., remote work, multi-state employers).
     - Test for spillovers by examining border counties or states adjacent to ban states.

#### **Empirical and Methodological**
4. **Improve the industry heterogeneity analysis.**
   - The current industry-specific results (Table 4) are hard to interpret due to noise. The authors should:
     - Group industries into broader categories (e.g., high/medium/low negotiation intensity) and test for heterogeneity.
     - Report event studies for high- vs. low-gap industries to show dynamic effects.
     - Use a continuous measure of pre-ban gender gaps (e.g., gap size) in a triple-difference regression.

5. **Enhance the race analysis.**
   - The Black-White earnings gap results (Table 5, Column 1) are not statistically significant but show a positive point estimate. The authors should:
     - Test whether the effect on Black workers’ earnings varies by gender (e.g., Black women vs. Black men).
     - Report hiring rate effects for Hispanic workers in an appendix.
     - Discuss whether the lack of statistical discrimination is robust to alternative specifications (e.g., county-level analysis).

6. **Clarify the TWFE vs. CS-DiD comparison.**
   - The paper emphasizes the discrepancy between TWFE and CS-DiD but does not fully explain why TWFE fails. The authors should:
     - Show the Bacon decomposition (even if only in an appendix) to illustrate negative weighting.
     - Report Sun-Abraham event-study coefficients to confirm the CS-DiD pattern.
     - Discuss whether the TWFE null result is due to heterogeneity or other factors (e.g., weights).

7. **Address compositional changes.**
   - The paper argues that hiring rates do not change, but this does not rule out compositional effects (e.g., bans may attract higher-quality female applicants). The authors should:
     - Test whether the skill composition of new hires changes (e.g., using education or age breakdowns).
     - Report separations rates by gender to assess whether bans affect turnover.

8. **Improve the placebo tests.**
   - The government-sector placebo (Table 5, Column 3) has only 149 observations, limiting power. The authors should:
     - Expand the placebo sample by including more quarters or states.
     - Test a placebo treatment in non-ban states (e.g., fake ban dates).
     - Report pre-trend tests for the government sector.

#### **Presentation and Interpretation**
9. **Standardize effect sizes.**
   - The paper reports log-point effects but does not consistently translate them into dollars or percentage changes. The authors should:
     - Add a table (or appendix) converting log-point effects to dollars at the mean male wage.
     - Clarify whether the 8.5% gap closure is relative to the pre-ban gap or the counterfactual gap.

10. **Discuss external validity.**
    - The paper focuses on 16 states, many of which are politically liberal. The authors should:
      - Test whether effects vary by state political lean (e.g., Democrat vs. Republican governors).
      - Discuss whether results generalize to states with weaker enforcement or different labor market conditions.

11. **Improve table readability.**
    - Tables 1, 3, and 4 are dense and hard to parse. The authors should:
      - Use horizontal lines to separate pre- and post-treatment periods in event studies.
      - Add stars to indicate significance in Table 4 (industry effects).
      - Report confidence intervals alongside standard errors in all tables.

12. **Clarify the sample.**
    - The paper mentions 41,855 observations but does not explain how this number is derived (e.g., 51 states × 20 industries × 44 quarters × 2 sexes = 89,760; why the discrepancy?). The authors should:
      - Explicitly state the sample construction (e.g., missing data, aggregation).
      - Report the number of treated and control observations in each table.

#### **Minor Suggestions**
13. **Add a map of ban states.**
    - A simple map showing adoption timing would help readers visualize the staggered rollout.

14. **Discuss enforcement.**
    - The paper briefly mentions enforcement variation but does not test its implications. The authors could:
      - Compare states with strong enforcement (e.g., California) to those with weak enforcement (e.g., Alabama).
      - Test whether effects grow over time as awareness of the ban increases.

15. **Expand the literature review.**
    - The paper cites key papers (Agan & Starr, Barach & Horton) but could better situate itself in the broader literature on:
      - Information frictions in labor markets (e.g., wage posting vs. negotiation).
      - Gender differences in negotiation (e.g., Babcock & Laschever).
      - Policy evaluations with staggered adoption (e.g., recent DiD debates).

16. **Address potential confounds.**
    - Other policies (e.g., minimum wage increases, paid leave) may coincide with salary history bans. The authors should:
      - Test whether ban states are more likely to adopt other pro-equity policies.
      - Include controls for contemporaneous policies in robustness checks.

---

### **Overall Assessment**
This is a strong paper that makes a genuine contribution to the literature on salary history bans and gender pay gaps. The use of QWI data and staggered DiD is appropriate, and the results are credible and policy-relevant. The authors should address the three essential points above (aggregation, race analysis, mechanism tests) to strengthen the paper further. With these revisions, the paper would be suitable for publication in *AER: Insights*.
