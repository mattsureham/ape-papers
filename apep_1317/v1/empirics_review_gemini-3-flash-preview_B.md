# V1 Empirics Check — google/gemini-3-flash-preview (Variant B)

**Model:** google/gemini-3-flash-preview
**Variant:** B
**Date:** 2026-04-02T13:28:10.141727

---

**Referee Report**

**Paper Title:** The Conscription Tax: Wartime Military Service and Academic Achievement in Colombia
**Reviewer:** Expert Referee (AER: Insights Format)

---

### 1. Idea Fidelity
The paper departs significantly from the original research design outlined in the Idea Manifest. The manifest proposed using the **municipal-level draft lottery (sorteo)** as a source of exogenous random variation to estimate the causal effect of *actual military service* (an IV strategy). 

Instead, the paper implements a **triple-difference (DDD)** design using gender, geographic conflict intensity, and the 2016 Peace Agreement. It shifts the research question from the impact of *serving* to the *anticipatory effect* of the draft threat. While the paper uses the same underlying context and data sources (ICFES/DANE), it abandons the lottery-based identification strategy—the most rigorous element of the original idea—in favor of a transparency-based variation that is more susceptible to confounding.

### 2. Summary
This paper investigates the human capital costs of mandatory military service during active civil conflict in Colombia. Using a triple-difference framework on ~920,000 standardized test scores, the author finds that males in high-conflict regions belonging to pre-peace cohorts score 0.42 points lower in math (secondary) and 2.4 points lower in quantitative reasoning (university). The author concludes that the threat of wartime conscription induces anticipatory disinvestment in education before service even occurs.

### 3. Essential Points
The following three issues are critical to the paper’s viability:

1.  **Identification Strategy vs. Original Contribution:** The original idea’s strength was the "unexploited natural experiment" of the lottery. By switching to a DDD, the paper enters a crowded literature on conflict and education. The current strategy relies on the assumption that no other gender-specific, region-specific shocks occurred at the same time as the 2016 Peace Agreement. For example, if the peace deal led to a differential expansion of blue-collar job opportunities for young men specifically in high-conflict zones, this would bias the result. The author must justify why the lottery data was discarded or, ideally, incorporate it to provide a cleaner causal estimate.
2.  **Socioeconomic Status (SES) as a Confounder:** The paper finds larger effects for high-SES students. However, in Colombia, high-SES individuals frequently use legal and illegal exemptions (e.g., buying the *libreta*) to avoid service. If high-SES males in conflict zones became *less* likely to serve after the peace deal relative to low-SES males (who couldn't afford to evade regardless), the DDD is capturing changes in the "avoidance" economy rather than just the "conscription threat."
3.  **The "Peace Deal" as a Multi-faceted Shock:** The 2016 agreement wasn't just about the draft; it involved land reform, crop substitution (coca), and local governance changes. These factors likely had gendered impacts on labor supply and educational incentives (e.g., changes in the opportunity cost of male labor in agricultural regions). Attributing the entire DDD coefficient to the "conscription tax" requires more rigorous exclusion of these simultaneous shocks.

### 4. Suggestions

**Data and Measurement:**
*   **Lottery Integration:** The author should attempt to find municipal-level lottery data. Even if not available for all years, a localized IV analysis using the lottery would provide a "Gold Standard" validation for the DDD results.
*   **The *Libreta Militar* Variable:** The DANE GEIH and Census 2018 data (mentioned in the manifest but underutilized in the paper) contain variables on military status. Using these to show that the probability of service actually dropped for males in high-conflict zones post-2016 is a necessary first stage for the DDD logic.
*   **Refining Conflict Intensity:** The binary "high/low" split based on homicides is blunt. I suggest using a continuous measure of *military* presence or *FARC activity* specifically, as these more directly relate to the draft threat than the general homicide rate.

**Empirical Specification:**
*   **Event Study Plots:** To support the parallel trends assumption, the author must provide an event study plot showing the male-female test score gap in high- vs. low-conflict departments for each birth cohort. The current "Conflict-era" binary group (pre-1998) is too broad.
*   **Migration Controls:** Use the census data to check if there were differential migration patterns for draft-age males out of high-conflict departments. If the "smartest" males fled the draft to Bogota, your "high-conflict" estimate is just a selection effect.
*   **The "Bachiller" vs. "Regular" Distinction:** As noted in the manifest, high school graduates (*bachilleres*) serve shorter, non-combat roles. Since the Saber 11 sample consists entirely of *bachilleres*, the "wartime combat" narrative in the paper might be overstated. The author should clarify that even "safe" service carries an opportunity cost.

**Interpretation:**
*   **Mechanism Testing:** To prove "anticipatory disinvestment," look at other secondary school outcomes. Do these males have higher absence rates? Lower grades in non-exam subjects?
*   **The 0.42 Point Magnitude:** The effect size is very small (0.037 SD). While statistically significant, the author should be more cautious in framing this as "eroding human capital" or a "life-or-death" consequence in the secondary school context. The Saber Pro results (0.07 SD) are more compelling and deserve more focus.
*   **Policy Counterfactuals:** Discuss what happened to the *cost* of the *libreta militar* after 2016. If the financial cost dropped alongside the service risk, the result is a "tax" in the literal sense.

**Final Assessment:** The paper is well-written and the triple-difference is a standard approach, but it misses the "Genuine Contribution" mark by ignoring the lottery-based identification that was the highlight of the original idea. To reach AER: Insights quality, it must either incorporate the lottery or provide much stronger evidence that the 2016 shock is not being confounded by broader changes in the conflict economy.
