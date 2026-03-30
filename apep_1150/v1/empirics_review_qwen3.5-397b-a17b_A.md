# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant A)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** A
**Date:** 2026-03-30T15:49:23.831246

---

# Referee Report

**Manuscript:** The Bed Cap: How Medicare Payment Cliffs Shrink US Hospitals
**Journal:** AER: Insights (Format)

## 1. Idea Fidelity

The paper largely adheres to the Original Idea Manifest, successfully executing the core empirical strategy of multi-threshold bunching estimation using CMS HCRIS data (2010–2023). The data source, running variable (total bed count), and primary thresholds (25, 50, 100) match the manifest precisely. The key innovation—decomposing regulatory bunching from round-number heaping using non-regulatory multiples—is implemented as proposed.

However, there are two notable deviations from the manifest's scope. First, the manifest promised "estimated threshold-specific elasticities" and "computed welfare costs using a common methodology." The paper reports normalized bunching statistics ($b$) but stops short of converting these into structural elasticities or dollar-valued deadweight loss estimates, which were central to the proposed contribution ("which Medicare designation threshold causes the most capacity distortion per dollar?"). Second, the manifest proposed a historical placebo using the pre-2003 CAH limit of 15 beds. Given the data starts in 2010, this is impossible; the paper correctly adapts by using urban hospital placebos, but this limitation should be explicitly acknowledged as a deviation from the original design due to data availability.

## 2. Summary

This paper provides a unified empirical assessment of how Medicare payment thresholds distort US hospital capacity. Using 80,009 hospital-year observations from CMS cost reports, the author estimates bunching at the 25-bed (CAH), 50-bed (RHC/REH), and 100-bed (DSH) thresholds. The key contribution is a methodological decomposition that separates regulatory incentives from cognitive round-number heaping, revealing that the CAH program induces capacity distortions an order of magnitude larger than other Medicare provisions.

## 3. Essential Points

The authors must address the following three issues to ensure the identification strategy is credible and the contribution meets the promised scope:

1.  **Missing Elasticity and Welfare Estimates:** The manifest explicitly promised "threshold-specific elasticities" and "welfare costs." Reporting bunching statistics ($b$) describes the *extent* of distortion but not the *responsiveness* (elasticity) or the efficiency cost. Without converting $b$ into an elasticity $\varepsilon$ (using the formula $b \approx \varepsilon \cdot \tau$, where $\tau$ is the implicit tax rate/payment wedge), the paper cannot answer the core policy question: which program causes the most distortion *per dollar* of payment differential? This conversion is standard in the bunching literature (e.g., Kleven 2016) and is essential for an *AER: Insights* policy audience.
2.  **Validity of the Heaping Counterfactual:** The identification strategy assumes that round-number heaping behavior is identical between CAH-eligible (rural) and non-CAH (mostly urban/larger) hospitals. However, administrative reporting cultures may differ systematically by hospital type. Rural hospitals may rely on different staffing or reporting software that induces different heaping patterns independent of incentives. The authors should test whether heaping at non-regulatory round numbers (e.g., 30, 40 beds) differs between rural non-CAH and urban hospitals. If heaping varies by hospital type, the decomposition ($b^{\text{reg}} = b^{\text{total}} - b^{\text{heap}}$) may be biased.
3.  **Clarification of the 100-Bed DSH Incentive:** The paper describes the DSH formula as favoring hospitals with 100 *or more* beds, implying an incentive to cross the threshold upward. However, bunching is estimated *at* 100 beds. If the incentive is to be $\geq 100$, we expect a "hole" at 99 and mass at 100+, but not necessarily a spike *at* 100 relative to 101 unless there is a cost to growing beyond 100. The mechanism here is less clear than the 25-bed notch (where crossing 25 loses CAH status). The authors must clarify whether the DSH incentive creates a notch (penalty for dropping below) or a kink, and why mass accumulates specifically at 100 rather than simply shifting from 99 to 100+.

## 4. Suggestions

The following recommendations are intended to strengthen the paper's empirical rigor, policy relevance, and clarity. While not strictly essential for publication, addressing them would significantly elevate the quality of the analysis and align it closer to the high standards of *AER: Insights*.

**1. Implement Structural Elasticity Calculations**
To fulfill the manifest's promise of comparing distortions "per dollar," you should calculate the implied behavioral elasticity for each threshold. The bunching estimator relates excess mass to the elasticity of bed supply with respect to the net-of-tax rate (or payment rate).
*   **Action:** Use the relationship $b = \varepsilon \cdot \tau$, where $\tau$ is the proportional payment jump at the threshold. You will need to estimate or cite the average payment differential for each program (e.g., CAH cost-based vs. PPS; DSH large urban vs. small urban). MedPAC reports often contain these margins.
*   **Benefit:** This allows you to state, for example, "The CAH program induces an elasticity of 0.5, while the DSH program induces 0.1," which is far more policy-relevant than raw bunching statistics. It also allows for a back-of-the-envelope welfare cost calculation (deadweight loss triangle), which was a key selling point of the original idea.

**2. Include Density Histograms**
Bunching papers rely heavily on visual evidence. While Tables 2 and 3 provide counts, the text references visual patterns ("visually striking," "architecture of regulatory cliffs") without including the actual density plots in the provided LaTeX.
*   **Action:** Generate and include three figures (one for each threshold) showing the empirical density (bars) overlaid with the counterfactual polynomial (line). Highlight the manipulation window and the excluded bins.
*   **Benefit:** Readers need to see the "hole" above the 25-bed threshold and the smoothness of the counterfactual to trust the identification. Visuals are critical for *Insights* formats to communicate the magnitude of the distortion quickly.

**3. Refine the Heaping Control Group**
To address the potential bias in the heaping decomposition (Essential Point 2), refine the control group for the 25-bed threshold.
*   **Action:** Instead of using all non-CAH hospitals to estimate heaping at 25 beds, restrict the control group to *rural* non-CAH hospitals. These hospitals face similar administrative environments and reporting constraints as CAH hospitals but lack the CAH financial incentive.
*   **Benefit:** This isolates the financial incentive from rural-specific reporting behaviors. If the bunching estimate remains stable using this stricter control, the causal claim is significantly strengthened.

**4. Discuss the "Necessary Provider" Exemption**
The Institutional Background notes that CAH eligibility requires $\leq 25$ beds, but there is a "necessary provider" exemption that allows some CAHs to exceed 25 beds (grandfathered or state-certified).
*   **Action:** Add a footnote or brief paragraph quantifying how many hospitals in your sample are CAH-designated but have $>25$ beds.
*   **Benefit:** If a significant number of CAHs operate above the threshold due to exemptions, it suggests the incentive is not binding for all, which affects the interpretation of the "missing mass" above 25 beds. It also explains any noise in the spike.

**5. Clarify Data Cleaning Discrepancies**
The manifest cited ~84,000 observations, while the paper reports 80,009.
*   **Action:** Briefly detail the cleaning steps that led to the reduction (e.g., duplicate reports, zero beds, implausible values).
*   **Benefit:** Transparency in data construction is vital for reproducibility, especially when using administrative data like HCRIS which often contains reporting errors.

**6. Expand on the REH Timing (2023)**
The manifest highlights the Rural Emergency Hospital (REH) conversion effective January 2023. The data includes FY2023.
*   **Action:** Discuss whether the 2023 data captures any early REH conversion effects. Since REH also requires $\leq 50$ beds, does the 50-bed bunching increase in 2023 compared to 2022?
*   **Benefit:** This provides a dynamic test of the policy mechanism. If the 50-bed spike grows in 2023, it reinforces the causal link between the regulation and the behavior.

**7. Policy Discussion on Marginal Cost of Public Funds**
The Conclusion asks whether access benefits justify the distortion. You can sharpen this by referencing the marginal cost of public funds.
*   **Action:** Briefly discuss that if the elasticity is high (as suggested by $b=17$), the deadweight loss per dollar of transfer is high. Contrast this with the policy goal (preventing closures).
*   **Benefit:** This moves the paper from a descriptive empirical exercise to a normative policy evaluation, fitting the *AER: Insights* mission.

**8. Standard Error Methodology**
The paper uses Poisson bootstrap replications (200).
*   **Action:** Consider increasing bootstrap replications to 1,000 for the final draft to ensure stability of the standard errors, especially for the smaller 50- and 100-bed thresholds where noise is higher.
*   **Benefit:** Enhances precision and confidence in the smaller estimates, which are currently less robust than the 25-bed estimate.

**9. Visualizing the "Hole"**
For the 25-bed threshold, the "missing mass" above the threshold is a key identifier of a notch.
*   **Action:** In the density figures, explicitly shade the region above 25 beds where mass is missing relative to the counterfactual.
*   **Benefit:** This visually demonstrates the optimization friction and the sharpness of the notch, distinguishing it from a kink where mass might spread out above the threshold.

**10. Addressing the 100-Bed Sensitivity**
The Discussion notes the 100-bed estimate is sensitive to polynomial degree.
*   **Action:** Consider using a local linear or quadratic fit rather than a global polynomial for the 100-bed threshold, given the sensitivity. Or, narrow the window further around 100 beds.
*   **Benefit:** If the result holds with a more flexible local fit, it mitigates concerns about overfitting the broader bed distribution around medium-sized hospitals.

By implementing these suggestions, particularly the elasticity calculations and visual density plots, the paper will fully realize the potential outlined in the Original Idea Manifest and provide a definitive answer on the comparative efficiency costs of Medicare's hospital payment architecture.
