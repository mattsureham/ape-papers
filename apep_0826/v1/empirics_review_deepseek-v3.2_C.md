# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant C)

**Model:** deepseek/deepseek-v3.2
**Variant:** C
**Date:** 2026-03-23T14:51:13.061002

---

## **Review of "Coal Dust in the Dark: MSHA's 2014 Respirable Dust Rule and Mining Employment Dynamics"**

### **1. Idea Fidelity**

The paper largely pursues the core idea from the manifest: using the 2014 MSHA rule's effective date and QWI data to estimate labor market effects. It correctly identifies the treatment date (Q3 2014), uses NAICS 212 (coal) and 211 (oil/gas) data from QWI, and employs a difference-in-differences (DiD) framework with a continuous treatment (2013 county coal share).

However, the paper **deviates significantly** from a key element of the proposed identification strategy. The manifest specified a **stacked-cohort DiD** (Callaway and Sant'Anna, 2021) to account for staggered treatment timing and heterogeneous effects. The submitted paper uses a **standard continuous-treatment, two-way fixed effects (TWFE) model**. This is a major departure. The TWFE estimator is potentially biased in this context because all counties are "treated" at the same time (Q3 2014) with heterogeneous intensity. The stacked design was meant to cleanly compare early-affected units to later-affected/control units within cohorts. The current specification risks contamination from post-treatment dynamics and may misattribute trends to the treatment.

Additionally, the manifest proposed using **NAICS 213 (mining support) as part of the control group**, but the paper's analysis focuses only on coal vs. oil/gas. The placebo test on NAICS 22 (utilities) mentioned in the manifest is not implemented.

### **2. Summary**

This paper investigates the employment impact of a major mine safety regulation. It finds no average effect of the 2014 MSHA dust rule on aggregate mining employment but reveals substantial heterogeneity: suggestive evidence of employment declines in Appalachian (underground) counties and relative gains in non-Appalachian (surface) counties. The central, sobering conclusion is that the contemporaneous oil price collapse was a far more potent driver of mining employment dynamics than the regulatory compliance cost.

### **3. Essential Points**

The following three issues are critical and must be convincingly addressed for the paper to be publishable.

**1. The Control Group is Compromised by a Massive, Asymmetric Shock.** The core identification assumption—parallel trends between coal-intensive and oil/gas-intensive counties—is invalidated by the 2014-2016 oil price crash. The event study (Table 2) shows significant pre-trend differences, and the main results (positive DiD coefficients) are explicitly interpreted as coal counties faring *relatively better* because the control group (oil/gas) was devastated. This is not a valid counterfactual for the regulatory effect. The paper acknowledges this but then proceeds to interpret the Appalachian/non-Appalachian split as a "mechanism," when it is more likely capturing the differential exposure of these regions to the oil price shock (non-Appalachian states often have both coal and oil/gas). **The fundamental research design fails to isolate the regulatory effect from overwhelming commodity market noise.**

**2. The Key Finding of Appalachian Harm is Statistically Weak and Not Robustly Isolated.** The headline heterogeneity result—a 23% employment decline in Appalachia—has a standard error (0.21) nearly as large as the point estimate. It is insignificant at conventional levels. To make this the paper's central narrative, the analysis must: (a) drastically improve precision (e.g., by using a more efficient estimator or a better-specified model), (b) provide direct evidence linking the estimated effect to the rule's mechanism (e.g., differential compliance costs for underground vs. surface mines, not just geography), and (c) rule out that this geographic split is merely proxying for differential exposure to other shocks like the Clean Power Plan or regional coal price dynamics.

**3. The Specification and Standard Errors Are Questionable.**
*   **Specification:** The use of a linear continuous treatment interaction (`CoalShare × Post`) imposes a constant proportional effect across counties, from 1% to 100% coal share. This is unlikely. The original stacked-cohort idea using quintiles was more flexible. The current specification could be misleading.
*   **Standard Errors:** Clustering at the state level (n=~50) may be insufficient. Mining employment is highly localized in a few states. Conley-HAC spatial corrections or two-way clustering (state and time) should be explored. The limited number of state clusters can lead to underestimated standard errors.

### **4. Suggestions**

**A. Redesign the Identification Strategy to Address the Oil Price Confound.**
*   **Implement the Proposed Stacked Design:** Revert to the manifest's plan. Use the Callaway & Sant'Anna (2021) estimator or a similar stacked cohort DiD (Cengiz et al., 2019). This better handles the single timing shock and allows for cleaner leads/lags analysis within cohorts defined by pre-treatment coal share.
*   **Find a Better Control Group:** The within-NAICS-21 control group is flawed. Consider:
    *   **Synthetic Control Methods:** Construct synthetic controls for major coal counties using donor pools from non-mining but otherwise similar counties.
    *   **Alternative Within-Sector Controls:** Focus comparison on **surface coal mining counties (largely non-Appalachian) vs. underground coal mining counties (Appalachian)**. This directly tests the mechanism (rule burden) while holding the commodity (coal) constant. Use mine-level data from MSHA to classify counties by underground share.
    *   **Triple-DiD Refinement:** The paper's triple-DiD (coal vs. oil/gas within county) is a good start but messy. Fully saturate it: `Y_{ict} = α_{ic} + γ_{ct} + λ_{it} + β*(Post_t * CoalIndustry_i * UndergroundShare_c) + ε_{ict}`, where `i` is industry (coal, oil/gas), `c` county, `t` time. The triple interaction `Post*Coal*UndergroundShare` is the cleanest test.

**B. Strengthen the Analysis of Heterogeneity and Mechanism.**
*   **Move Beyond Geography:** Use a direct, continuous measure of regulatory exposure burden. Merge MSHA mine data to calculate, for each county, the **pre-rule violation rate for dust standards** or the **capital intensity of local mines** (proxy for compliance cost capacity). Interact this with `Post`.
*   **Improve Precision for Appalachian Analysis:** If sticking with the geographic split, use bootstrapped or wild cluster bootstrap standard errors to address the small number of Appalachian state clusters. Consider aggregating to the state or commuting-zone level for this subset analysis to gain precision.
*   **Test for Mechanism More Directly:** The rule's cost came from CPDMs and ventilation. If possible, use data on mine equipment sales or utility costs in mining counties as intermediate outcomes.

**C. Conduct Rigorous Robustness and Sensitivity Analyses.**
*   **Spatial Correlation:** Test sensitivity of inferences to spatial error structures.
*   **Pre-Trend Controls:** Instead of just showing broken pre-trends, formally test and correct for them using the methods of Freyaldenhoven et al. (2021) or Bilinski and Hatfield (2020). Include linear or quadratic county-specific time trends interacted with `CoalShare`.
*   **Falsification Tests:** Execute the manifest's suggested placebo test on NAICS 22 (utilities) as formally as the main test. Also, run placebo treatments in earlier years (e.g., 2012) on the full sample to demonstrate no effect when none should exist.
*   **Standardized Reporting:** The appendix Table 4 is good. Ensure all main results are reported with standardized effect sizes relative to pre-treatment outcome SDs, as suggested by the AER: Insights style.

**D. Improve Narrative and Interpretation.**
*   **Reframe the Contribution:** The paper's most credible contribution may not be the estimated effect size, but the **methodological demonstration** that in commodity sectors, market shocks can completely obscure regulatory impacts, and that researchers must use extreme care in selecting control groups. The title and abstract should reflect this nuanced takeaway.
*   **Clarify the "Null" Result:** The "precisely estimated null" language is slightly misleading. The confidence interval for the main coefficient (0.1524 ± 0.22) is wide and includes economically meaningful negative values. Discuss the bounds of what can be ruled out.
*   **Discuss Magnitudes:** Compare the implied Appalachian effect (-23%) to MSHA's own Regulatory Impact Analysis cost estimates. Is the magnitude plausible? A back-of-the-envelope calculation linking compliance costs to expected job losses would greatly strengthen the discussion.

**Conclusion:** The paper tackles an important, novel question with creative data linkage. In its current form, however, the identification strategy is not credible due to the overwhelming confounding oil price shock. The authors must fundamentally rethink the control group and empirical design, ideally moving towards a more direct test of the underground vs. surface mechanism. The suggestions above provide a path to a much stronger, publishable paper.
