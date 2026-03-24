# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant A)

**Model:** deepseek/deepseek-v3.2
**Variant:** A
**Date:** 2026-03-13T12:14:31.489252

---

### **Referee Report: N2024-001 "Closing the Golden Door: Individual Occupational Mobility After the 1924 Immigration Quota Act"**

This paper uses a novel, large-scale linked census panel to investigate the individual-level impact of the 1924 Immigration Quota Act on native-born workers' occupational mobility. The analysis is executed with impressive scale and technical care. The core finding—a precisely estimated null effect on occupational upgrading—is important and challenges a persistent narrative. However, the paper’s credibility and contribution hinge on addressing several critical identification and interpretative issues.

---

#### **1. Idea Fidelity**
The paper faithfully executes the core research plan outlined in the original manifest. It leverages the specified IPUMS MLP 1920-1930 linked panel with the correct sample restrictions, constructs the proposed Bartik-style county-level treatment variable (share of foreign-born from restricted origins), and employs a continuous-treatment DiD framework with state and initial-occupation fixed effects. It successfully includes the planned 1910-1920 placebo test and explores heterogeneity. The paper correctly identifies and reports a null main result. One minor deviation is the focus on six primary origin countries instead of the broader list mentioned in the manifest, but Column 5 of Table 1 shows this choice does not alter the conclusion.

#### **2. Summary**
This paper provides the first individual-level analysis of how the sharp, exogenous reduction in Southern and Eastern European immigration caused by the 1924 Johnson-Reed Act affected the occupational trajectories of native-born men. Using a linked panel of over 10 million workers, the author finds precisely estimated null effects on occupational upgrading, farm exit, and geographic mobility. A key ancillary finding is a significant *negative* effect on transitions to homeownership, suggesting the restriction dampened local economic dynamism.

#### **3. Essential Points**
The following issues must be convincingly addressed for publication.

**1. The "Immigrant Share" Treatment and Endogenous Settlement Patterns.** The core identification assumption is that the 1920 county-level share of restricted-origin immigrants is uncorrelated with other determinants of 1920-1930 occupational trends, conditional on state and occupation FEs. This is the paper's most vulnerable point. Immigrants did not settle randomly in 1890 or 1920; they clustered in dynamic, industrializing counties with specific sectoral mixes (e.g., manufacturing, mining). These same local economic fundamentals likely influenced native occupational mobility trends in the 1920s—a decade of profound structural transformation (electrification, auto industry growth, agricultural decline). While state FEs absorb broad regional trends, and initial occupation FEs are a powerful control, they may not fully capture *county-specific* growth trajectories correlated with both high immigrant shares and different opportunities for occupational change. The author must engage more deeply with this threat. A richer set of robustness checks is required, such as controlling for pre-1920 county-level trends in industrialization, manufacturing employment growth (1910-1920), or crop/value-added composition. The placebo test in Table 4 is reassuring but not definitive, as the confounding factor could be a trend that accelerated post-1920.

**2. Mechanism and Interpretation of the Homeownership Result.** The significant negative effect on homeownership transitions is intriguing but currently under-explained and risks misinterpretation. The paper posits it reflects "weakened local housing demand and economic dynamism." This needs rigorous testing. Is the effect driven by a decline in housing prices or construction activity in high-exposure counties? Can the author rule out alternative mechanisms? For instance, if natives perceived high-exposure counties as less desirable due to the withdrawal of immigrant communities that provided local services or supported certain industries, the mobility result might reflect selective out-migration. The correlation between homeownership and occupational null results should be probed: could the loss of local economic activity have counteracted any potential occupational gains from reduced labor competition, resulting in a net null? This finding is too important to be a footnote; it demands a dedicated mechanism analysis.

**3. Interpreting the Null: Labor Market Adjustment and Power.** The paper convincively rules out large positive effects. However, a precise null can arise from multiple equilibria: (a) true zero effect (perfect complements), (b) offsetting mechanisms, or (c) rapid labor market adjustment that dissipated the shock by 1930. The discussion leans toward (a) but does not sufficiently engage with (b) and (c). The author should test for more immediate effects. Was there a change in the occupational distribution of *new labor market entrants* (young natives) after 1924? Did wage differentials across occupations in high-exposure counties narrow, suggesting a price adjustment that precluded quantity adjustment? While the 1920-1930 window is data-constrained, the argument would be strengthened by discussing the timing of adjustment and citing complementary historical wage studies.

#### **4. Suggestions**
The following recommendations would strengthen the paper considerably.

*   **Treatment Variable Construction:** Consider an alternative, perhaps more salient, treatment measure: the predicted decline in the *working-age* immigrant population based on pre-1920 arrival cohorts and quota cuts, rather than the simple stock share. This might better capture the actual labor supply shock experienced by local employers.
*   **Robustness & Specification Checks:**
    *   **Pre-Trends Graphic:** Present an event-study-style figure showing the relationship between quota exposure and occupational change for placebo inter-census periods (1900-1910, 1910-1920) alongside the main 1920-1930 result. This visually reinforces the parallel trends argument.
    *   **Spatial Correlation:** Acknowledge and test for spatial autocorrelation in residuals. High-exposure counties are geographically clustered (Northeast, Midwest). Conley standard errors or spatial HAC estimators might be appropriate.
    *   **Weighting:** The estimates are unweighted. Consider weighting by initial county population to ensure representativeness and assess if results are driven by many small counties.
    *   **Alternative Clustering:** Given the treatment is at the county level and there are only 48 states, two-way clustering (state and county) may be imperfect. Demonstrate robustness to wild cluster bootstrap at the state level, which is more conservative.
*   **Deepen the Heterogeneity Analysis:** The manifest suggested the effect should be "concentrated in occupations competing with immigrants." The null is interesting, but this should be tested explicitly. Interact the treatment with the degree of occupational overlap between natives and immigrants in that county in 1920 (using a Duncan index or share of immigrants in the native's 1920 occupation). A true null would be evidenced by no gradient across this interaction.
*   **Strengthen the Discussion/Conclusion:**
    *   **Contextualize the Null:** More directly contrast this individual-level null with Tabellini (2020), who found positive effects using city-level data. Discuss the differences (aggregation, outcome measurement) that might explain the divergence.
    *   **Policy Implications:** Sharpen the policy takeaway. The result suggests that the *occupational* rationale for the 1924 restriction was flawed. However, the homeownership finding implies potential unintended *economic* costs. This nuanced point should be front and center.
    *   **Broader Literature:** Briefly relate the findings to modern studies (e.g., the Mariel Boatlift literature) where null results on native wages are often found, emphasizing that even a historically massive, permanent shock did not produce the expected substitution.
*   **Presentation and Clarity:**
    *   **Table 1:** The quartile labels in the header (Q1, Q3, Q2, Q4) are out of order. Correct this.
    *   **Standardized Effects:** The standardized effect size table in the appendix is excellent. Integrate a discussion of these magnitudes (e.g., -0.006 SD) into the main text to emphasize economic (un)importance.
    *   **Abstract:** The abstract mentions "homeownership transitions" but does not state the direction of the effect. Clarify: "significantly reduced native homeownership transitions."

**Overall, this is a promising and well-executed paper that leverages fantastic new data to speak to a classic question. With rigorous attention to the essential points above, it has the potential to make a significant contribution to the literature on immigration, labor markets, and historical political economy.**
