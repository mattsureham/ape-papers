# V1 Empirics Check — google/gemini-3-flash-preview (Variant B)

**Model:** google/gemini-3-flash-preview
**Variant:** B
**Date:** 2026-03-24T16:28:45.244871

---

**Referee Report**

**Title:** The Stability Paradox: Tipped Minimum Wages Close the Racial Earnings Gap but Not the Turnover Gap in U.S. Restaurants
**Data:** QWI (Quarterly Workforce Indicators) 2010–2023

---

### 1. Idea Fidelity
The paper aligns closely with the original idea manifest. It successfully executes the transition from the conceptual "earnings-stability paradox" to an empirical framework using the QWI administrative panel. It maintains the core identification strategy (DDD comparing restaurants to a placebo industry across race and tipped wage regimes) and moves beyond the cross-sectional statistics of the manifest to a formal panel analysis. The inclusion of the New York event study as a specific test of the mechanism strengthens the original proposal's request for "large within-state" variation.

### 2. Summary
This paper documents a "Stability Paradox" in the U.S. restaurant industry: while increasing the tipped minimum wage effectively eliminates the Black-White earnings gap, it has no discernible impact on the persistent 8–10 percentage point gap in quarterly separation rates. Using a DDD approach and a case study of New York’s 2016 reform, the author argues that tipped wage policy successfully mitigates customer-side "price" discrimination (tips) but fails to address employer-side "quantity" discrimination (retention and scheduling).

### 3. Essential Points

1.  **The "Earnings" Definition in QWI:** A critical vulnerability is whether QWI "Earnings" (variable `EarnS`) actually includes the tips that current policy debates center on. In most states, employers only report tips to state U.I. agencies (the source of QWI) if they are used to meet the minimum wage or are officially declared by the employee for tax purposes. If Black workers under-report tips at different rates than White workers, or if employers in "Tip Credit" states only report enough tips to reach the $7.25 floor, your "earnings equalization" result might be a mechanical artifact of reporting requirements rather than a change in take-home pay. You must explicitly address the QWI's capturing of tip income.
2.  **The Insurance Placebo:** While NAICS 524 (Insurance) is a standard "low-tipping" industry, it is a poor counterfactual for restaurant labor markets. The demographic composition, education requirements, and cyclical sensitivity of insurance agents and restaurant servers are vastly different. A more compelling placebo would be another low-wage service industry with no tipping, such as **Limited-Service Restaurants (Fast Food, NAICS 722513)** or **Grocery Stores (NAICS 4451)**. This would better isolate the "tip credit" mechanism from general low-wage labor market shocks.
3.  **Treatment Variable Construction:** You define the "Tipped Ratio" as (Tipped MW / Regular MW). However, the "Regular MW" itself is changing significantly in many of your treated states (CA, NY, AZ). If a state raises both the regular and tipped MW simultaneously, the "Ratio" might stay constant while the absolute wage floor for Black workers rises. You need to demonstrate that your result is driven specifically by the *closing of the gap* between the two wages, not just the general rise in the wage floor (which also compresses racial gaps).

---

### 4. Suggestions

**Measurement and Data**
*   **The 25-Employee Threshold:** You drop cells with fewer than 25 employees. In many rural counties, Black employment in restaurants is low. This might bias your sample toward large, urban, multi-unit firms (e.g., Darden, Brinker) where HR practices are more standardized. Please provide a table comparing the characteristics of included vs. excluded counties to ensure the "Paradox" isn't just a phenomenon of large corporate restaurants.
*   **Tenure vs. Separations:** Since you have QWI data, you can look at `EarnS` specifically for "Full-Quarter" employees (`EarnFullQT`). This would help disentangle whether the earnings gap closes because hourly pay is equalized or because the *composition* of workers staying full quarters changes.

**Identification and Robustness**
*   **Alternative Control Group (DDD):** As noted in Essential Point 2, I strongly recommend using NAICS 722513 (Fast Food) as the control. It shares the same seasonal trends and labor pool as Full-Service restaurants but has no tip credit. This would be a much "cleaner" triple-difference.
*   **Event Study Dynamics:** In Table 3, the pre-trends for earnings ($t-5$ to $t-2$) look somewhat unstable (hovering around -200). It would be helpful to plot this as a figure with 95% confidence intervals. If the Black-White earnings gap was already narrowing before 2016, the "Price Channel" argument weakens.
*   **Weighting:** You use employment weights. Minimum wage papers are often sensitive to weighting (see Manning, 2021). Since racial populations vary wildly across counties, show a specification in the appendix that uses "Black population weights" or "Inverse Probability Weights" to ensure the result isn't driven solely by Cook County (IL) and the five boroughs of NYC.

**Conceptual Framing**
*   **The Scheduling Mechanism:** You mention "scheduling favoritism" in the discussion. In restaurants, the "Best" shifts (Friday/Saturday nights) yield the highest tips. If Black workers are systematically kept off high-tip shifts, a higher base wage closes the earnings gap even if the scheduling discrimination persists. This supports your "quantity channel" theory—consider citing the "Shiftless" literature or recent work on the "Predictable Scheduling" laws in Oregon/Seattle.
*   **Selection into Employment:** Does OFW policy change *who* gets hired? If a higher tipped wage makes these jobs more "desirable," White workers might crowd out Black workers (statistical discrimination). If the "newly hired" Black workers in OFW states are higher-ability than those in tip-credit states, your earnings result is selection, not a policy effect. Checking the "Hires" (`HirA`) rate by race would be a simple and powerful addition to the "Paradox" story.

**Editorial/Formatting**
*   **Table 1:** The "B-W gap" in Panel B is listed as 8.0pp and 9.1pp. To a reader, this looks like the gaps are nearly identical. This actually *supports* your paradox (policy doesn't change the gap), but you should emphasize this "null effect" more clearly in the text.
*   **JEL Codes:** Add `J15` (Economics of Minorities).
