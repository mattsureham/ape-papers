# V1 Empirics Check — openai/gpt-oss-120b (Variant A)

**Model:** openai/gpt-oss-120b
**Variant:** A
**Date:** 2026-03-23T13:25:55.243041

---

**1. Idea Fidelity**

The paper follows the original manifest closely. It uses the QWI quarterly‐level county‑industry‑age panel, constructs the pre‑shock “tech‑share’’ (NAICS 51 + 54) as the intensity measure, and exploits the FY2004 H‑1B cap reduction. The triple‑difference (DDD) set‑up – county tech intensity × young‑worker indicator × post‑cap – is exactly the design proposed. The authors also add a second shock (the 2008 lottery) in the background, but the empirical work focuses on the 2004 cut, as in the manifest. All key components (quarterly dynamics, age‑group comparison, industry heterogeneity checks) are present, so the paper stays faithful to the original idea.

**2. Summary**

The paper investigates how a sudden reduction in the H‑1B visa cap in 2004 affected native workers in professional‑technical services. Using a DDD strategy that compares 25‑34‑year‑old workers to 45‑54‑year‑old workers across counties with varying pre‑shock tech employment shares, and exploiting the quarterly QWI data, the author finds that the cap cut reduced quarterly earnings of young native professionals by roughly 4 % (per standard‑deviation of tech intensity) and lowered separations, while employment effects are imprecise. The effects are concentrated in H‑1B‑intensive industries, supporting a complementarity interpretation.

**3. Essential Points**

1. **Identification Concerns – Parallel Trends and Differential Age‑County Shocks**  
   The DDD relies on (i) similar pre‑trends for young vs. old workers across counties with different tech shares, and (ii) no age‑specific shocks that coincidentally affect high‑tech counties at the time of the cap cut. The event‑study plots show some pre‑trend deviations at *t‑8* and *t‑7* (2001‑2002), which the authors attribute to the dot‑com recession, but they do not formally test whether those early leads bias the estimate of the post‑treatment dynamics (e.g., by estimating placebo DDDs using leads as “post’’). The paper should present a more rigorous pre‑trend test (e.g., joint test of all leads) and, if violations are found, consider alternative specifications (e.g., county‑specific linear trends, propensity‑score weighting, or a synthetic‑control type approach).

2. **Treatment Intensity Measurement – Potential Endogeneity of Tech Share**  
   The tech‑share is measured in 2002 Q1, before the cap cut, which is appropriate. However, the share may be correlated with unobserved county trends (e.g., differential exposure to the early 2000s recession, state‑level tech policies, or pre‑existing immigration inflows). The current specification only includes state‑quarter fixed effects, which may not fully absorb such heterogeneity. The authors should either (a) add county‑specific linear time trends, (b) control for baseline lagged outcomes (e.g., 2001–2002 employment growth), or (c) instrument the tech share with a pre‑policy “shif‑share’’ based on national industry composition (as in classic shift‑share designs) and report the first‑stage.

3. **Interpretation of the Earnings Effect – Magnitude and Economic Significance**  
   The paper reports the coefficient as “‑0.41 log points per standard deviation of tech intensity’’ and translates it into a 1.8 % earnings loss (≈ \$48 per quarter). While statistically significant, this magnitude is modest relative to typical quarterly earnings. Moreover, the authors claim this “contradicts the substitution view’’ without providing a direct link between the earnings loss and productivity complementarity. A more convincing argument would (i) estimate the implied productivity loss using a production‑function framework, (ii) compare the earnings change to the wage elasticity estimates in the immigration literature, and (iii) discuss whether the observed earnings dip could arise from compositional changes (e.g., fewer high‑skill hires) rather than pure complementarity.

**4. Suggestions**

*Methodological Enhancements*

- **Robustness to Alternative Age Comparisons**: The paper drops the 35‑44 group because the triple interaction is absorbed, but a more informative test would be to estimate a *continuous* age interaction (e.g., interacting tech share with a spline in age) to see whether the effect truly peaks at the youngest cohort. This would strengthen the claim that H‑1B workers substitute primarily for 25‑34 natives.

- **Placebo Tests Using Other Policy Changes**: The 2008 lottery introduction is mentioned but not used. Running the same DDD around the 2008 lottery (as a second “post’’) would provide a useful placebo: if no effect (or a smaller effect) is found, it supports the identification.

- **Alternative Clustering**: State‑level clustering may be too coarse given only 46 clusters. Consider a two‑way clustering by state and county‑year, or wild‑cluster bootstrap inference, to assess the sensitivity of standard errors.

- **Dynamic Specification with Lagged Treatments**: The event‑study currently includes a limited set of leads/lags. Extending the window to at least 12 quarters pre‑ and post‑treatment (as the data allow) and plotting confidence bands would give a clearer picture of the dynamics, especially whether the earnings impact dissipates or persists.

- **Controls for Local Labor‑Market Conditions**: Include county‑quarter unemployment rates, industry‑specific productivity measures (e.g., value‑added per worker from BEA), or state‑level immigration inflows from other visa categories to rule out confounding shocks.

*Data & Presentation*

- **Descriptive Checks**: Provide summary statistics of H‑1B visa counts (if available) by county or at least at the MSA level to verify that the tech‑share indeed proxies for H‑1B exposure. Even a correlation table between tech‑share and actual H‑1B counts would bolster the relevance of the instrument.

- **Visualization of Pre‑Trends**: Include a graph of the DDD coefficient for each lead/lower lead with confidence intervals, rather than a table of a few leads. Visual inspection helps readers assess the parallel‑trend assumption.

- **Clarify the “Tech Share’’ Construction**: Explain why NAICS 51 is added to NAICS 54 and discuss sensitivity to excluding NAICS 51. Some readers may wonder whether the inclusion inflates the treatment intensity in counties where information services dominate but H‑1B presence is low.

- **Standardized Effect Sizes**: The appendix presents SDEs, but the main text should briefly discuss economic significance in those terms, perhaps comparing to the mean quarterly earnings growth rate for the sector.

*Theoretical Framing*

- **Link to Task‑Based Models**: Expand the discussion of how the observed earnings drop maps onto the task‑based complementarity literature. For instance, construct a simple model where the marginal product of natives depends on the share of immigrant‑complementary tasks, and show that a 1.8 % earnings loss is consistent with plausible parameter values.

- **Alternative Mechanisms**: Address other plausible mechanisms, such as “crowding out’’ of native entry (fewer hires leading to lower earnings because of reduced on‑the‑job learning) or “selection’’ (high‑ability native workers leaving tech counties). Even a brief discussion of these alternatives, together with evidence (e.g., the unchanged separations), would pre‑empt reviewer criticism.

*Writing & Structure*

- **Consistency of Terminology**: Occasionally the paper switches between “cap cut’’ and “cap reduction’’ – pick one term and use it throughout. Similarly, refer to “young’’ workers consistently (25‑34) rather than sometimes “young’’ and sometimes “25‑34’’ in tables.

- **Table Labels and Notes**: Some tables (e.g., Table 3) list only “Log Employment’’ but the text refers to other outcomes. Ensure each table’s caption reflects the outcome(s) displayed. Add notes on the fixed effects included, and note the number of counties after each sample restriction.

- **Citation of Recent Literature**: The bibliography could be updated with the latest H‑1B studies (e.g., Doran & Peri 2023, Knochenhauer et al. 2024) to position the contribution more clearly.

*Potential Extensions (optional)*

- **General Equilibrium Implications**: While the paper focuses on the short‑run quarterly dynamics, a brief simulation of welfare effects (e.g., using estimated earnings losses multiplied by labor supply elasticities) could broaden the policy relevance.

- **Spillovers to Nearby Counties**: Because high‑tech counties may attract talent from neighboring regions, exploring spatial spillovers (e.g., using a distance‑weighted tech‑share of adjacent counties) could uncover additional adjustment channels.

---

**Overall Assessment**

The paper makes a valuable contribution by leveraging the quarterly QWI panel to uncover the speed of adjustment to an exogenous H‑1B cap reduction. The identification strategy is sound in principle, and the triple‑difference design is well‑executed. However, to solidify the credibility of the causal claims, the authors should strengthen the parallel‑trend evidence, address possible endogeneity of the tech‑share intensity, and provide a richer economic interpretation of the earnings effect. Addressing the three essential points and incorporating the suggested robustness checks and clarifications will substantially improve the manuscript and make it suitable for publication in *AER: Insights*.
