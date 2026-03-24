# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant B)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** B
**Date:** 2026-03-17T23:47:25.254061

---

# Referee Report

**Paper:** Banned from the Land, Pushed Up the Ladder: Alien Land Laws and Japanese Occupational Sorting in the United States
**Format:** AER: Insights

## 1. Idea Fidelity

The paper adheres closely to the Original Idea Manifest. It successfully implements the proposed identification strategy (staggered DiD with individual-level linked census panels), utilizes the specified data source (IPUMS MLP), and addresses the core research question regarding the causal effect of Alien Land Laws (ALLs) on occupational sorting. The exclusion of pre-treated states (California, Arizona) and the use of white farmers as a placebo group match the design parameters outlined in the manifest.

However, there are minor deviations that require clarification. The Manifest specifies "8 states newly treated 1921-23," whereas the Paper analyzes "7 newly treated states." Additionally, the Manifest's smoke test indicates a 25.0% farm exit rate for Japanese in treated states, while Table 1 in the paper reports a 42.9% exit rate for the analytical sample. While these discrepancies likely stem from sample restrictions (e.g., restricting to baseline farmers vs. all Japanese), explicitly reconciling these numbers would strengthen fidelity to the pre-analysis plan.

## 2. Summary

This paper provides compelling evidence that discriminatory Alien Land Laws (1921–1923) forced Japanese immigrants out of agriculture and into higher-status non-farm occupations. Using linked census panels and a triple-difference design with white farmers as a placebo, the author shows that treated Japanese farmers were 18 percentage points more likely to exit farming and gained significant occupational prestige relative to controls. The findings suggest that exclusionary policies can generate paradoxical upward mobility when targeted groups possess transferable human capital, though potentially at the cost of wealth accumulation and dignity.

## 3. Essential Points

The paper is strong but requires attention to three critical issues before publication:

1.  **Inference with Few Clusters:** The identification relies on variation across only 7 treated states and 11 control states. State-clustered standard errors may be unreliable with so few clusters, potentially inflating significance (e.g., the $t=3.0$ for farm exit). The authors must demonstrate robustness using wild cluster bootstrap procedures or permutation tests (randomization inference) to ensure the results are not driven by a single influential state.
2.  **Sample Construction Discrepancies:** The difference between the Manifest's "8 newly treated states" and the Paper's "7 states," as well as the divergence in baseline farm exit rates (25% vs. 43%), needs explicit explanation. If a state was dropped due to data sparsity, this should be documented to avoid concerns about cherry-picking.
3.  **Linking Bias and Selection:** While the paper notes that linking is based on name/age rather than occupation, differential linking rates by state or occupation stability could bias the results. If successful occupational switchers were more likely to be linked in 1930 than those who remained in marginalized farming, the occupational gains could be overstated. A test of linking rates across treatment/control states is necessary.

## 4. Suggestions

The following recommendations are intended to enhance the robustness, clarity, and impact of the paper. Addressing these points will significantly strengthen the contribution to the literature on discrimination and occupational mobility.

** Econometric Robustness and Inference **
Given the small number of treatment clusters (7 states), conventional asymptotic inference is risky. I strongly recommend implementing a wild cluster bootstrap (e.g., Webb correction) to verify the p-values reported in Tables 2 and 3. Additionally, consider a leave-one-out analysis where each treated state is dropped sequentially to ensure the results are not driven by a single outlier (e.g., Washington or Oregon, which had larger Japanese populations). If the effect disappears when dropping a specific state, the claims of generalizability should be tempered. Finally, while the paper mentions the 1924 Johnson-Reed Act, it would be useful to explicitly test for pre-trends using the 1910–1920 census link for the subset of individuals available, even if treatment hadn't started, to confirm parallel trends in occupational trajectories prior to the ALL wave.

** Mechanism and Occupational Detail **
The paper finds an increase in Duncan Occupational Score, but the specific nature of this upgrade remains opaque. Did Japanese farmers move into small business ownership (e.g., grocery stores, nurseries), skilled trades, or service work? The Duncan score aggregates these, but the economic implications differ. Providing a breakdown of the top 5 destination occupations for treated vs. control farmers would enrich the narrative. For instance, if the movement was primarily into self-employed retail rather than wage labor, this supports the "human capital transfer" hypothesis (marketing skills from farming applied to retail). If it was into low-wage service work with high prestige scores, the welfare interpretation changes. Linking this to the historical literature on Japanese *kenjin* (prefectural) networks would also strengthen the mechanism argument—did community networks facilitate this specific type of switching?

** Welfare Interpretation and Wealth **
The title "Pushed Up the Ladder" implies welfare improvement, but occupational prestige scores do not capture wealth or income volatility. Alien Land Laws explicitly prevented land *ownership*, which is a primary vehicle for wealth accumulation and collateral. A farmer moving to retail might have higher occupational prestige but lower net worth and higher income risk. I suggest adding a caveat in the Discussion or Conclusion that distinguishes between occupational status (prestige) and economic wealth. Did the ALLs prevent Japanese immigrants from building intergenerational wealth via land equity, even if it boosted their occupational status? Acknowledging this trade-off prevents the reader from interpreting the findings as a net benefit of discrimination. The reference to "dignitary harm" in the Discussion is good; expand this to explicitly mention wealth suppression.

** Clarifying Sample Discrepancies **
To resolve the fidelity issues noted in Section 1, add a footnote or appendix table detailing the sample attrition. Specifically: (1) Which of the 8 manifest states was dropped in the paper (likely Louisiana or New Mexico due to sample size)? (2) Reconcile the farm exit rates. If the Manifest's 25% refers to all Japanese and the Paper's 43% refers to baseline farmers, state this clearly. Transparency here ensures reproducibility and aligns the pre-analysis plan with the final output.

** Policy Context and External Validity **
The connection to modern Alien Land Laws (2025) is timely but requires nuance. The 1920s Japanese population was distinct in its high rates of self-employment and community cohesion. Modern targeted populations (e.g., Chinese nationals) may have different labor market attachments (e.g., higher rates of wage labor in tech vs. agriculture). Briefly discussing the external validity limits would strengthen the policy implication. Are the "forced sorting" benefits contingent on the targeted group having specific entrepreneurial human capital? If so, modern laws might not generate the same "upgrading" effect but simply displacement.

** Visual Presentation **
For an *Insights* format, visual evidence is crucial. Consider adding a coefficient plot for the triple-difference estimates or a histogram of occupational score changes for treated vs. control groups. A map showing the treated states and the magnitude of effects by state would also help readers quickly grasp the geographic variation. Ensure all tables include confidence intervals alongside standard errors for easier interpretation.

** Writing and Tone **
The writing is generally excellent, but the abstract could be punchier. Instead of "I track 630 Japanese farmers," consider "Using linked census data, I show..." to emphasize the finding over the method. In the Conclusion, reinforce the key takeaway: discrimination reshapes economic trajectories in unpredictable ways, but "upgrading" does not equal "justice." This balances the empirical finding with the normative reality.

** Final Thought **
This is a high-quality paper with a novel data application to a historically important policy. By tightening the inference checks and clarifying the welfare implications, this work could become a definitive study on the economic consequences of Alien Land Laws.
