# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant A)

**Model:** deepseek/deepseek-v3.2
**Variant:** A
**Date:** 2026-03-13T17:36:12.528100

---

### **Referee Report**

**Paper:** "The Saturday Soldier: Labor Market Returns to Mexico's Compulsory Military Lottery"

---

### **1. Idea Fidelity**

The paper successfully pursues the core idea from the manifest: it leverages the Mexican Sorteo Militar as a natural experiment to estimate the labor market returns to compulsory military service. It correctly identifies the institutional setting (lottery, Saturday service, *cartilla*), uses the proposed ENOE data, and implements a gender-based Difference-in-Differences (DiD) strategy (Strategy A from the manifest).

However, the paper **deviates from the original plan in three significant ways**:
1.  **Data Scope:** The manifest proposed pooling 20 years of data (2005-2024, ~3M male obs.) to maximize power and explore dynamics. The paper uses only 8 quarters (2018-2019), severely limiting its ability to analyze long-term effects, cohort trends, or the proposed 2025 policy validation.
2.  **Identification Strategy:** The manifest proposed three complementary strategies (A: Male-Female DiD, B: Cross-Municipality IV, C: Age Discontinuity). The paper uses only Strategy A, providing a less robust and multi-faceted identification argument than intended.
3.  **Outcome Focus:** While employment and formalization are central, the manifest's broader question about "returns to compulsory weekend service" (encompassing education, occupation, industry) is narrowed primarily to an employment/formality result. The mechanism discussion is strong, but the analysis feels less comprehensive than the original vision.

### **2. Summary**

This paper provides the first economic evaluation of Mexico's long-running military lottery, a massive and clean natural experiment. Using a male-female DiD design around age 18, it finds that lottery eligibility causes a large increase in employment (13.6 pp) and formal employment (11.6 pp) for young men, with no effect on conditional earnings. The authors argue compellingly that the mechanism is credentialing (obtaining the *cartilla militar*) rather than human capital accumulation, highlighting a unique "formalization channel" for part-time conscription in a developing economy.

### **3. Essential Points**

The following issues must be convincingly addressed for the paper to be credible. They are fundamental to the identification strategy and interpretation.

**1. The Validity of the Female Control Group in the DiD Design is Unproven and Threatened by Lifecycle Differences.**
The core identification assumption—that the male-female outcome gap would evolve smoothly through age 18 absent the lottery—is highly questionable and not adequately defended.
*   **The Problem:** Males and females have starkly different labor market trajectories in adolescence, as shown in Table 1 (e.g., male employment at 17 is 37.3% vs. 18.2% for females). This large and growing pre-existing gap makes it difficult to attribute a *change* in the gap at 18 solely to the lottery. The "parallel trends" test (Table 3) only shows the gap is stable from ages 15-17, not that the *levels* are comparable. A diverging trend could easily begin precisely at age 18 due to non-lottery, gender-specific factors (e.g., social norms, differential returns to education, marriage market pressures).
*   **Required Action:** The authors must provide much stronger evidence for the design. This should include:
    *   **Event Study Graph:** A visual event study plot (coefficients with confidence intervals) is essential to assess pre-trends and dynamic effects. The current table is insufficient.
    *   **Placebo Tests on Older Cohorts:** Test if similar "jumps" in the male-female gap occur at other ages (e.g., 21, 25) where no lottery occurs. If found, it would invalidate the design.
    *   **Discussion of Confounders:** Seriously engage with and rule out other age-18, gender-asymmetric shocks (e.g., gender-specific social expectations upon reaching legal adulthood).

**2. The Analysis Lacks a Direct Connection to the Lottery Assignment.**
The paper infers the effect of the *lottery* from a gender-based DiD, which is an indirect and potentially confounded path.
*   **The Problem:** The estimated coefficient `Male × Post18` captures the *intent-to-treat* effect of being an 18-year-old male subject to the lottery system. It does not isolate the effect of *drawing a white ball* vs. a black ball. The mechanism (the *cartilla* credential) differs by ball color, but the design cannot distinguish between men who served and those who did not. The LATE scaling by 0.4 is speculative without individual lottery data. The effect could be driven by the *threat* of service, the act of registration, or other gender-specific correlates of turning 18.
*   **Required Action:**
    *   **Pivot to Proposed Alternative Strategies:** The authors must implement **Strategy B (Cross-Municipality IV)**. If lottery assignment is random *within* municipalities, but the *share* assigned to white balls varies *across* municipalities (due to quotas, historical rates, or the 2025 shock), this can be used as an instrument for service. This would provide a direct, male-only estimate of the effect of service itself.
    *   **Clarify Parameter:** Be explicit that the current estimate is a Reduced Form effect of lottery eligibility/gender-conscription, not a clean LATE of service. Tone down causal claims about "service" and refocus on "lottery eligibility."

**3. The Chosen Data Window (2018-2019) Undermines the Project's Potential and Raises Questions.**
*   **The Problem:** Using only two years of data is a major self-limitation. It reduces statistical power, prevents analysis of long-term effects (are these jobs sustained?), and makes it impossible to conduct the compelling validation test using the **2025 policy shock** mentioned in the manifest and institutional section. It also precludes checks for stability of effects over time or across business cycles.
*   **Required Action:** **Use the full data span (2005-2024) as originally planned.** This is non-negotiable for a credible analysis. The 2025 shock, if data is available, should be a central part of the paper, not a footnote.

### **4. Suggestions**

These recommendations would substantially improve the paper's contribution, robustness, and exposition.

**A. Empirical & Identification**
*   **Implement the Manifest's Full Design:** Fulfill the original proposal by adding:
    *   **Strategy B (Municipality IV):** Use municipal-level treatment intensity (historical white ball share) as an instrument. This is the most direct way to estimate the effect of service.
    *   **Strategy C (Age Discontinuity):** Implement a sharp RDD at age 18 using birth month timing within the survey. This can complement the DiD and is free from gender-comparison concerns.
*   **Expand Mechanism Tests:**
    *   Test if effects are stronger in industries or occupations where the *cartilla* is known to be required (e.g., government jobs, security, transportation).
    *   Interact the treatment with baseline education to see if the credential effect is stronger for those with lower education (for whom a formal credential may be a binding constraint).
*   **Conduct Robustness Checks:**
    *   Use the **full 2005-2024 data**. Present results separately for early and late periods.
    *   Control for state-specific linear time trends.
    *   Estimate using a stacked regression design to account for cohort-specific shocks.

**B. Data & Measurement**
*   **Formal Employment Definition:** The definition (social security access) is standard. Briefly discuss if this aligns with the *cartilla*'s relevance (it likely does for salaried jobs).
*   **Earnings Measurement:** Address potential measurement error in informal sector earnings. Consider using imputed earnings or bounding exercises.
*   **Sample Definition:** Justify the age 15-30 window. For long-term effects, consider extending to older ages (e.g., 35-40) using the full data.

**C. Presentation & Narrative**
*   **Reframe Contribution:** Emphasize that this is the **first** study of a massive, decades-old randomization. The novelty is immense.
*   **Strengthen the Institutional Section:** Provide a citation for the 40/60 historical split and the 2025 change. Include a map or table showing geographic variation in treatment rates if available.
*   **Improve Tables/Figures:**
    *   Create a clean event study graph (Figure 1).
    *   In Table 2, do not repeat the reference row for age 17. It's confusing.
    *   Add a table summarizing the first-stage and LATE estimates from the proposed IV strategy.
*   **Discuss Limitations More Deeply:**
    *   Acknowledge that the gender DiD is vulnerable to differential lifecycle trends.
    *   Discuss that without lottery microdata, defiers (non-compliance) could bias the LATE.
    *   Mention that the credential effect might be diminishing over time if enforcement of *cartilla* requirements is weakening.

**D. Literature & Context**
*   **Deepen the Development Literature Link:** Connect more directly to papers on labor market formalization in Latin America (e.g., Ulyssea, Levy). Your mechanism is a novel, state-driven formalization channel.
*   **Clarify Comparison to Other Conscription Studies:** Your null effect on earnings isn't just due to part-time service; it's because the mechanism is credentialing, not human capital destruction *or* accumulation. This is a key theoretical point.

**Overall:** The paper identifies a truly exceptional natural experiment and points to a fascinating mechanism. However, in its current form, it relies on a fragile identification strategy and does not exploit the data's full potential. By addressing the **Essential Points**—particularly by implementing a direct IV strategy and using the full data—the authors can transform this from a suggestive and novel analysis into a compelling and credible flagship study.
