# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant A)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** A
**Date:** 2026-03-25T15:56:38.661432

---

# Referee Report

**Paper:** Shutting Down the Tremors, Shutting Down the Jobs? The Employment Costs of Oklahoma's Seismicity Regulation
**Format:** AER: Insights

## 1. Idea Fidelity

The paper largely pursues the core research question outlined in the manifest: estimating the local employment costs of Oklahoma's seismicity regulation using staggered spatial variation. However, there are notable deviations from the proposed empirical design and data usage that diminish the claimed novelty.

First, the manifest emphasized the use of "novel daily well-level injection data (OCC Form 1012D)" as a first stage to construct treatment intensity based on *injection volume*. The submitted paper mentions this data in the institutional background but reverts to a binary county-level treatment indicator based on directive documentation for the main specification. The continuous intensity specification (Table 2, Col 2) uses *pre-directive mining employment share* rather than *injection volume*, which is a significant departure from the manifest's identification strategy.

Second, the manifest proposed using Census QWI (hires/separations) and FHFA HPI to explore wealth and turnover channels. The submitted paper relies exclusively on BLS QCEW employment and wage data. While QCEW is sufficient for a null result on net employment, the absence of QWI data removes the ability to detect labor churning (e.g., layoffs followed by rehiring in compliance roles), which is central to the paper's proposed mechanism.

Finally, the sample period was shortened from the proposed 2012–2020 to 2014–2020. While likely due to data availability, this reduces the pre-period power for parallel trends testing.

## 2. Summary

This paper estimates the local labor market effects of Oklahoma's 2015–2017 wastewater injection volume caps, designed to mitigate induced seismicity. Using a staggered difference-in-differences design on county-level employment data, the author finds no evidence that the regulation reduced total private employment or wages, and some evidence that mining support services employment increased. The results suggest that seismicity regulation can achieve hazard reduction without the employment costs typically associated with environmental policy.

## 3. Essential Points

The paper addresses an important and novel question, but the identification strategy requires significant strengthening before the results can be considered credible. I have three critical concerns:

1.  **Validity of the Control Group (Oil vs. Non-Oil Counties):** The identification relies on comparing 20 regulated counties (all with active Arbuckle disposal wells) against 57 control counties (which lack regulated wells). A substantial portion of the 57 control counties likely have minimal oil and gas activity compared to the treated counties. Given the concurrent oil price collapse (2014–2016), treated counties were exposed to both the regulatory shock and a much larger industry-specific shock than many control counties. While time fixed effects absorb aggregate price shocks, they do not absorb differential exposure to oil price volatility. The fact that NAICS 211 (Extraction) shows a positive (though insignificant) coefficient in treated counties is concerning; typically, one would expect high-exposure counties to suffer more during a bust. The control group must be restricted to counties with comparable oil industry exposure but without Arbuckle disposal wells, or the analysis must explicitly control for county-level oil exposure intensity interacted with oil prices.
2.  **Treatment Intensity Measurement:** The manifest proposed using well-level injection volumes to measure treatment intensity. The current binary measure (Regulated County = 1) is noisy because regulatory pressure varied significantly *within* counties (some wells capped, others not) and across counties (some had higher baseline volumes). Using mining employment share as a proxy for intensity (Table 2, Col 2) conflates the regulatory shock with general oil sector health. To credibly claim the effect is driven by the *regulation* and not general industry trends, the author must construct a continuous treatment measure based on the actual mandated volume reductions (e.g., baseline injection volume per county) using the OCC 1012D data promised in the manifest.
3.  **Mechanism Evidence for Positive Mining Employment:** The finding that mining support services (NAICS 213) employment *increased* in regulated counties is counterintuitive for a regulation restricting volume. The proposed mechanism—that compliance requires labor (monitoring, well modifications)—is plausible but currently speculative. Without evidence on compliance costs, establishment counts, or wage bills, this result risks being interpreted as a statistical artifact or a reflection of unobserved heterogeneity (e.g., regulated counties were simply more resilient). The paper needs to provide direct evidence linking the employment uptick to compliance activities rather than general production.

## 4. Suggestions

The following recommendations are intended to help the authors strengthen the empirical design and clarify the contribution. Implementing these changes would significantly improve the paper's credibility and alignment with the original proposal.

**Refining the Control Group and Identification**
*   **Restrict the Sample:** The current control group of 57 counties is too heterogeneous. I recommend restricting the control group to counties that have oil and gas production (NAICS 211 > 0) but do not have Arbuckle disposal wells subject to caps. This ensures that both treated and control units are exposed to the oil price bust, isolating the regulatory variation. If this reduces power too much, consider a synthetic control method at the county level to construct a better counterfactual for the treated counties.
*   **Oil Price Interaction:** Explicitly interact the treatment indicator with local oil exposure (e.g., pre-period oil employment share) and the real oil price. This allows the model to estimate whether regulated counties deviated from the *expected* path given their oil exposure during the bust.
*   **Event Study Visualization:** The appendix mentions an event-study specification using Sun and Abraham (2021), but the coefficients are not plotted in the main text. For an AER: Insights paper, visual evidence of parallel trends is essential. Include a figure plotting dynamic treatment effects with confidence intervals for at least 8 pre-periods. If pre-trends diverge during the 2014 price drop, the identification is compromised.

**Leveraging the Novel Data (OCC Form 1012D)**
*   **Construct Volume-Based Intensity:** Return to the manifest's proposal. Use the OCC 1012D data to calculate the total mandated volume reduction per county (e.g., sum of baseline volumes for capped wells). Use this as a continuous treatment variable instead of the binary indicator. This exploits the variation in regulatory strictness across counties rather than just presence/absence.
*   **First-Stage Compliance:** Show a first-stage regression demonstrating that counties with higher mandated reductions actually reduced injection volumes more. This validates that the treatment variable captures the intended regulatory shock.
*   **Within-County Variation:** If possible, exploit variation across wells within counties. Some wells were capped while others were not. A within-county well-level analysis (if employment data can be mapped or proxied) would eliminate county-level confounds entirely.

**Deepening the Mechanism Analysis**
*   **Labor Churning (QWI):** The manifest indicated feasibility with Census QWI data. I strongly encourage incorporating this. Net employment might be flat, but gross hires and separations could reveal significant churn (e.g., disposal workers fired, compliance workers hired). This would nuance the "null cost" conclusion—there may be distributional costs even if aggregate employment is stable.
*   **Establishment Dynamics:** Use the QCEW "number of establishments" variable. Did existing firms expand hiring, or did new compliance-focused firms enter? This helps distinguish between intensive and extensive margin adjustments.
*   **Wage Bill vs. Employment:** If employment stayed flat but wages rose (or vice versa), the total labor cost implication differs. Table 3 shows null wage effects, but combining wage and employment into a total wage bill measure would provide a clearer picture of the economic cost to firms.

**Clarifying the Contribution**
*   **CCS Implications:** The discussion on Carbon Capture and Storage (CCS) is promising but brief. Expand this to specify *which* type of regulation is transferable. Oklahoma's regulation was reactive (post-earthquake) and volume-based. CCS regulation will likely be proactive and pressure-based. Clarify whether the "null cost" result holds because the regulation was flexible (operators could choose how to reduce volume) or because the disposal market was inelastic.
*   **Power Analysis:** With only 20 treated counties, power is a concern. Report a minimum detectable effect size (MDES) given the standard errors and cluster count. This helps readers interpret the null result—is it truly zero, or simply too noisy to detect a 5% decline?
*   **Robustness to AOI Exclusion:** The manifest mentions an "Area of Interest" (AOI) with 38 high-volume wells treated later (2017). The paper focuses on OWRA/OCRA. Include a robustness check excluding or separately treating AOI counties to ensure the results are not driven by the later wave of regulation.

**Presentation and Formatting**
*   **Table 1 (Summary Stats):** Add a row for "Baseline Injection Volume" or "Oil Production Volume" to demonstrate the economic similarity (or difference) between treated and control counties. Currently, the table shows employment but not the underlying industrial activity that drives the treatment.
*   **Abstract Precision:** The abstract claims a "precisely estimated null." Given the standard errors (e.g., 0.024 on log employment), clarify the confidence interval. A 95% CI might still allow for a 5% employment decline, which is economically meaningful in a small county.
*   **Data Availability:** Since the paper highlights novel data usage, include a statement on whether the cleaned OCC 1012D dataset will be made available to other researchers. This would significantly increase the paper's citation potential and contribution to the field.

By addressing the control group validity and fully utilizing the well-level injection data as originally proposed, this paper has the potential to be a definitive study on the labor market effects of seismicity regulation. Currently, the results are suggestive but vulnerable to confounds from the oil bust. Strengthening the identification strategy will ensure the "free lunch" conclusion is robust.
