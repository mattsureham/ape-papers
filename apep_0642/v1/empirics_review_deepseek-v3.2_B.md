# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant B)

**Model:** deepseek/deepseek-v3.2
**Variant:** B
**Date:** 2026-03-13T17:39:48.040556

---

### **Referee Report**

**Paper:** “Regulatory Whack-a-Mole: Cross-Media Pollution Substitution in Response to Clean Air Act Inspections”

---

### 1. Idea Fidelity

The paper adheres very closely to the original research idea. It faithfully implements the core elements outlined in the manifest:
*   **Research Question:** It directly tests for facility-level, cross-media pollution substitution in response to Clean Air Act (CAA) inspections.
*   **Data Sources:** It utilizes the linked universe of EPA ICIS-Air inspections and Toxics Release Inventory (TRI) data, exactly as proposed.
*   **Identification Strategy:** The empirical analysis is built around the proposed triple-difference design (facility-chemical × pre/post × air vs. non-air).
*   **Novelty:** It correctly positions itself as the first causal, facility-level test of cross-media substitution, distinguishing its contribution from the cross-plant and cross-program literature cited in the manifest.

The paper deviates from the manifest only in minor, justifiable ways: the sample period starts in 2005 rather than 1987 (likely for data consistency and to avoid early TRI reporting issues), and the initial feasibility check’s sample size estimate was slightly high. These do not compromise the core idea. The paper fully delivers on the promised analysis.

### 2. Summary

This paper provides the first causal evidence that facility-level environmental enforcement in one medium (air) leads to the displacement of pollution to other, un-inspected media (water and land). Using a triple-difference design with high-resolution TRI data, it finds that a CAA inspection reduces a facility’s air emissions of a given chemical by approximately 5% but increases its releases of the same chemical to non-air media by about 2%. This substitution effect is concentrated among chemicals specifically regulated under the CAA, pointing to strategic regulatory avoidance rather than a general production slowdown.

### 3. Essential Points

The paper is well-executed and makes a compelling case. However, three critical issues must be addressed to solidify the causal interpretation and policy relevance.

1.  **Defend the “Quasi-Random Timing” Assumption More Rigorously.** The identification strategy hinges on the claim that the timing of a facility’s first FCE within the sample period is as-good-as-random, conditional on fixed effects. The paper mentions that scheduling is driven by “inspector availability, geographic routing, and capacity constraints,” but this is asserted rather than demonstrated.
    *   **Required Action:** Provide direct evidence supporting this claim. Conduct a balancing test: regress the timing of the first inspection (or a binary for “early vs. late inspection” within a cohort) on pre-treatment facility characteristics (e.g., lagged total releases, lagged air releases, facility size, industry). Show that these predictors are not statistically significant. If possible, cite or replicate evidence from prior work using EPA inspection data. Failing to convincingly rule out selection into inspection timing is the most significant threat to the paper’s validity.

2.  **Reconcile the Treatment Definition with the “Whack-a-Mole” Analogy and Address Dynamic Effects.** The analysis uses a simple, binary “post-first-inspection” indicator. This is a reasonable starting point, but it may poorly capture the ongoing, dynamic game implied by the title.
    *   **Required Action:** (a) Justify the focus on the *first* inspection. Is the effect persistent, or does it decay? If a facility is inspected again in year t+3, does substitution recur? An event-study graph focusing on the first event is a good start, but the discussion should engage with the reality of recurring inspections. (b) More importantly, the finding that **water releases decrease** (Table 2) directly contradicts the core substitution narrative and needs an explicit explanation. Is this driven by facilities that also face CWA inspections? The control for “simultaneous CWA inspections” mentioned in the manifest is absent in the paper. This must be included and discussed. The possibility of a positive “spillover” effect on overall compliance for some facilities/media complicates a pure substitution story.

3.  **Clarify the Magnitude and Environmental Significance of the “Leakage.”** The paper states that 29% of the air reduction (in pounds) is offset by increased non-air releases, but this calculation is ambiguous and the environmental implications are undersold.
    *   **Required Action:** (a) Provide a clear, tabulated back-of-the-envelope calculation: total estimated pounds of air reduction vs. total estimated pounds of non-air increase for the average treated facility-chemical-year. Acknowledge the challenges of the log specification and zero-inflation in this calculation. (b) Move beyond pounds to discuss **toxicity-weighted or damage-weighted** releases. A pound of benzene shifted from air to water has very different health consequences. While performing a full damage assessment may be beyond scope, the discussion must explicitly frame the “1.8% increase” in terms of potential harm, citing literature on differential exposure pathways (as mentioned in the manifest). This transforms the finding from a statistical result into a concrete policy problem.

### 4. Suggestions

The following recommendations are aimed at improving clarity, robustness, and impact.

**A. Empirical Strategy & Robustness**
*   **Placebo Test:** Conduct a placebo test where you pretend the “treatment” is a randomly assigned inspection year. Do this 100+ times and plot the distribution of the key coefficients (Post×Air, Post×NonAir). This visually strengthens the case that the observed effects are unlikely to occur by chance.
*   **Alternative Clustering:** The choice to cluster at the facility level is good. Consider also presenting results with two-way clustering (facility and year) or Conley standard errors to account for potential spatial correlation, as facilities in the same region may be inspected by the same team and face similar market conditions.
*   **Functional Form:** The paper appropriately uses log(1+x) and IHS. For the mechanism test (Table 4), consider a triple-interaction specification (Post × Air × CAA_Chemical) within the full sample, rather than splitting. This is more efficient and provides a direct test of whether the substitution effect is *significantly larger* for CAA chemicals.
*   **Heterogeneity by Enforcement Stringency:** The result on high-enforcement states is intriguing but buried in the text. Make this a formal heterogeneity analysis (e.g., splitting by state-level enforcement expenditures per capita or inspections per facility). This directly tests whether stronger regulatory pressure exacerbates substitution.

**B. Mechanism & Interpretation**
*   **Deepen the Mechanism Test:** The CAA chemical split is excellent. Supplement it by testing whether substitution is stronger for chemicals with higher abatement or disposal cost differentials between air and non-air media (though this data may be hard to acquire).
*   **Explore the Role of Multi-Program Facilities:** Theoretically, the incentive to substitute is strongest for facilities permitted under multiple statutes (CAA, CWA, RCRA). Can you identify these “multi-program” facilities (e.g., via ICIS-NPDES linkage) and test if the substitution effect is concentrated there?
*   **Discuss Alternative Explanations More Thoroughly:** Could the non-air increase be due to *increased reporting accuracy* post-inspection (e.g., firms audit all their waste streams)? Or changes in production processes that genuinely generate more non-air waste? Acknowledge and argue against these more systematically.

**C. Presentation & Discussion**
*   **Policy Implications:** The recommendation for “integrated inspections” is apt. Go further: quantify the potential gain. If a hypothetical integrated inspection avoided the 1.8% leakage, what would the net reduction be? Discuss the practical barriers (cost, inspector expertise, statutory silos) more concretely to show policy realism.
*   **Visualization:** The paper needs at least one key figure. A clear event-study graph plotting coefficients for air and non-air releases from t-5 to t+5 would immediately convey the pre-trends and dynamic effects.
*   **Introduction & Abstract:** The abstract and introduction are very well-written. Ensure the abstract’s final sentence explicitly mentions the policy implication (e.g., “…suggesting medium-specific enforcement systematically overstates net pollution reduction.”).

**D. Data & Appendix**
*   **Sample Construction Transparency:** The appendix describes the data well. Add a flow chart (or a detailed table) showing the sample selection: starting with all TRI-ICIS matches, then applying the “first inspection” and ±5-year window filters, and finally the requirement for ≥2 pre/post observations. Report how many facilities/observations are dropped at each step.
*   **Linkage Quality:** The 99.8% FRS linkage rate for the Ohio test in the manifest is impressive, but the main paper uses a national sample with a 51.6% match rate. Discuss the representativeness of the matched sample. Are matched facilities larger, in different industries, etc.? A balance table between matched and unmatched TRI facilities would alleviate concerns.

---
**Overall Assessment:** This is a strong, novel, and policy-relevant paper that makes a genuine causal contribution. The empirical design is clever and well-suited to the question. Addressing the **Essential Points**—particularly on selection into inspection timing and the puzzling water result—is crucial for publication. The **Suggestions** offered can further enhance its robustness and impact. With satisfactory revisions, this paper would be an excellent fit for a journal like *AER: Insights*.
