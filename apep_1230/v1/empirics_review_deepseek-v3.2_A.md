# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant A)

**Model:** deepseek/deepseek-v3.2
**Variant:** A
**Date:** 2026-04-01T09:42:45.319815

---

**Referee Report: “Gatekeepers of the Good Death: How Enhanced Oversight of Hospice Entry Reshaped End-of-Life Markets”**

---
### **1. Idea Fidelity**

The paper largely adheres to the core research question and identification strategy outlined in the original manifest. It uses the CMS PPEO activation in July 2023 as a quasi-experiment in a difference-in-differences (DiD) design, comparing treated states (AZ, CA, NV, TX) to all others. The data sources (CMS PECOS enrollment data, Hospice Quality Reporting data) match those specified. The paper successfully delivers on analyzing the policy’s effect on new hospice certifications and the for-profit share, which were central outcomes in the manifest.

However, the paper **deviates in one notable aspect**: the manifest lists “per-beneficiary spending” as a primary outcome, but the submitted paper does not present any analysis of spending or utilization. Instead, it substitutes cross-sectional quality comparisons (HCI scores, visits near death). This is a significant omission, as the manifest positioned end-of-life spending as a key market outcome. The paper also does not leverage the “Wave 2” expansion (GA, OH in Dec 2025) for out-of-sample validation as suggested, ending its analysis in 2025Q4.

---
### **2. Summary**

This paper provides the first causal evidence that targeted federal oversight (CMS’s Provisional Period of Enhanced Oversight) dramatically reduced new hospice provider entry, with the effect entirely concentrated among for-profit providers. Using a DiD design, it finds an 80% decline in new enrollments in treated states, driven by for-profit entrants, while nonprofit entry was unaffected. The results suggest the policy successfully screened out providers whose business models relied on low-scrutiny environments, potentially linked to fraudulent activity.

---
### **3. Essential Points**

The following three issues are critical and must be convincingly addressed for the paper to be publishable.

**1. The California Confound and Threat to Identification**
California’s state-level hospice enrollment moratorium (Jan 2022) preceded the federal PPEO by 18 months. The paper includes a robustness check excluding California but does not adequately address the resulting identification threat. The parallel trends assumption for the DiD is potentially violated if California’s pre-existing decline in enrollments (due to its own policy) is trend-divergent from other states. This is not just a issue of magnitude (as addressed by dropping CA), but of *validity*. The event study in Table 2 shows a negative (though insignificant) point estimate at t-2, which could be the start of California’s moratorium effect. The author must:
*   Formally test for parallel trends **excluding California** from both treated and control groups for the pre-period. The primary specification should arguably be a “triple-difference” (DDD) that exploits variation between for-profit and nonprofit entry *within* treated states (excluding CA), or a more rigorous staggered adoption estimator that accounts for California’s earlier treatment.
*   Discuss whether the PPEO effect in AZ, NV, and TX alone is a policy-relevant estimand, given California’s dominant market share.

**2. Omission of Spending/Utilization Outcomes and Weak Quality Analysis**
The original question concerned “end-of-life spending” and market outcomes. The paper replaces this with a cross-sectional, post-treatment comparison of quality measures (HCI, visits). This analysis is not causal and is poorly aligned with the research design.
*   **Spending Analysis Must Be Added:** The author should analyze per-beneficiary Medicare spending (available in CMS utilization data) as a secondary outcome. Does reduced for-profit entry affect aggregate spending or intensity of service use in treated states? This is a direct policy question.
*   **Quality Analysis Needs a Causal Framework:** The current quality comparison (Table 3, Panel B) is confounded by pre-existing differences. The author should either (a) frame it purely as descriptive context motivating *why* CMS targeted these states, not as a result of PPEO, or (b) attempt a provider-level analysis comparing quality *trends* for existing providers in treated vs. control states (though this is a distinct question from entry).

**3. Interpretation of the “For-Profit” Effect and Mechanism**
The finding of a null effect on nonprofit entry is striking. However, the interpretation that PPEO specifically screened out “fraud-prone” for-profits is only one possibility. A compelling alternative is that the *cost* of compliance with enhanced oversight (prepayment review, site visits) is fixed and disproportionately deters smaller, capital-constrained entrants, who happen to be for-profit. This is a story about scale and capital, not necessarily fraud propensity.
*   The author must test this alternative by examining heterogeneity within for-profits (e.g., chain-affiliated vs. independent, based on ownership data). If the effect is driven by independent, small providers, the capital-constraint mechanism gains support.
*   The discussion should more carefully separate the empirical finding (PPEO deterred for-profit entry) from the interpretation (it deterred *fraudulent* entry). The high claim denial rate among reviewed providers is supporting evidence, but not direct proof regarding the deterred margin.

---
### **4. Suggestions**

**Empirical & Specification Refinements:**
*   **Inference:** The use of randomization inference (RI) and wild cluster bootstrap is excellent and necessary. Please report the RI p-value for the key nonprofit result (Column 3 of Table 1) to formally show the null is precise.
*   **Event Study Visualization:** The event study results in Table 2 should be presented as a conventional plot (coefficients with confidence intervals) in the main text. This visually assesses parallel trends and effect dynamics more intuitively than a table.
*   **Address Displacement:** The paper briefly mentions geographic displacement as a limitation. This is a first-order concern for welfare and policy interpretation. Can you test for an increase in new enrollments in bordering states or states with similar demographic profiles after July 2023? Even a simple analysis would greatly strengthen the paper.
*   **Sample Construction:** Clarify the time frame. The abstract says “2017 to 2025,” but the post-period includes quarters through 2025Q4. With treatment in 2023Q3, this is only 10 post-period quarters. Ensure the pre-period is sufficiently long (e.g., 2017Q1-2023Q2) to establish a stable baseline.

**Presentation & Narrative:**
*   **Motivation:** The introduction excellently sets up the for-profit “problem.” Strengthen it by citing specific OIG or GAO reports detailing the types of fraud (e.g., recruiting ineligible patients, phantom billing) suspected in these states.
*   **Results Narrative:** When presenting the main result, emphasize that the pre-treatment mean of 17.6 new enrollments/quarter is for the *four treated states combined*, not per state. The -14 effect is thus an average across them. The large standard errors reflect the small number of treated clusters.
*   **Table & Figure Improvement:**
    *   **Table 1:** Label columns (2) and (3) more clearly as “For-Profit Entry” and “Nonprofit Entry.” Add a row showing the RI p-value for the nonprofit specification.
    *   **Figure Suggestion:** Create a map of the US showing treated states (Wave 1 and Wave 2), shading intensity perhaps by pre-treatment for-profit entry growth. This instantly communicates the geographic concentration.
*   **Discussion & Policy Implications:**
    *   Expand the discussion of *why* nonprofit entry was unaffected. Is it because they are inherently more compliant, have different revenue models, or are less likely to enter these particular markets? This gets at the core screening mechanism.
    *   Discuss the welfare trade-off explicitly: Reduced fraudulent entry is a benefit, but did the reduction in overall entry limit patient access or choice? The null effect on nonprofits may mitigate this concern, but it should be discussed.
    *   Connect the findings more deeply to the literature on regulation and market structure. The result that targeted scrutiny can reshape ownership composition is a novel contribution beyond the well-known fact that regulation reduces entry.

**Minor Points:**
*   The abstract states “PPEO states now have lower HCI scores…” This implies a causal effect of PPEO on quality, which the design cannot support. Rephrase to indicate these are pre-existing or compositional differences.
*   Check the provider counts in Table 1, Panel B. It lists 3,659 providers in PPEO states and 3,235 in others, totaling 6,894, which differs from the 6,943 stated in the text/data section.
*   In Section 5 (Robustness), mention that the “leave-one-out” analysis dropping Texas yields an insignificant p-value (0.164). Acknowledge that the effect is not uniformly strong across all four states, which is reasonable given different market sizes.

**Conclusion:**
This paper tackles a timely, policy-relevant question with a clever quasi-experiment and a clear, important finding: enhanced oversight selectively curtailed for-profit hospice entry. The core analysis is sound, but the issues raised in Section 3—particularly the California confound and the missing spending analysis—are substantial. Addressing them rigorously will transform a promising draft into a compelling publication. The paper has the potential to make a significant contribution to health economics and regulation literature.
