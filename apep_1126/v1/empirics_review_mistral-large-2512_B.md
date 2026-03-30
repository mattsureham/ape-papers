# V1 Empirics Check — mistralai/mistral-large-2512 (Variant B)

**Model:** mistralai/mistral-large-2512
**Variant:** B
**Date:** 2026-03-30T11:32:59.398421

---

### 1. **Idea Fidelity**

The paper closely adheres to the original idea manifest, pursuing the core research question of whether Canada’s cannabis legalization generated cross-border enforcement spillovers in US border counties. Key elements of the identification strategy—such as the border-pair difference-in-differences (DiD) design, the use of UCR arrest data, and the focus on drug arrests, property crime, and DUI—are all preserved. The paper also incorporates the COVID-19 border closure as a diagnostic tool, a feature not explicitly mentioned in the manifest but highly relevant to the mechanism.

However, there are two notable deviations:
- **Sample restriction**: The manifest proposed including 12 border states, but the paper restricts to 8 prohibition states (excluding WA, VT, ME, and MI due to their pre-existing legalization status). This is a justified refinement but narrows the scope.
- **Outcome focus**: The manifest mentioned property crime and DUI as outcomes, but the paper focuses almost exclusively on drug arrests. While this is a reasonable prioritization, the absence of these outcomes should be acknowledged.

Overall, the paper remains faithful to the manifest’s core contribution while making defensible adjustments.

---

### 2. **Summary**

This paper exploits Canada’s 2018 cannabis legalization to estimate cross-border enforcement spillovers in US border counties. Using a DiD design with 51 border and 406 interior counties in 8 prohibition states, the authors find no evidence that Canadian legalization increased drug arrests in nearby US counties. The 95% confidence interval rules out positive spillovers larger than ~3 arrests per 100,000 (17% of the pre-period baseline). A three-regime design (pre-legalization, COVID closure, post-reopening) further suggests that cross-border trafficking is unlikely to drive enforcement patterns. The paper contributes novel evidence on international drug policy spillovers, with implications for countries considering legalization.

---

### 3. **Essential Points**

The paper is well-executed and makes a credible contribution, but three critical issues must be addressed:

1. **Mechanism ambiguity**:
   - The paper argues that the null result reflects "no enforcement externality," but the outcome (drug arrests) conflates enforcement effort and underlying drug activity. The COVID closure diagnostic is clever, but the interpretation is underdeveloped. If spillovers operate through cross-border trafficking, why do arrests *increase* during the closure (when trafficking should decline) and remain elevated post-reopening? The authors should:
     - Clarify whether the COVID results are consistent with alternative mechanisms (e.g., substitution to domestic trafficking, enforcement reallocation).
     - Test whether border seizures (CBP data) correlate with arrest patterns, as this would strengthen the trafficking interpretation.

2. **Sample representativeness**:
   - The restriction to 8 prohibition states excludes 4 border states (WA, VT, ME, MI) with partial legalization. While this sharpens the legal discontinuity, it may limit external validity. The authors should:
     - Report results including all 12 border states (even if noisier) to assess sensitivity.
     - Discuss whether spillovers might differ in states with pre-existing legalization (e.g., WA, where legal markets may have crowded out cross-border flows).

3. **Power and precision**:
   - The paper emphasizes the "bounded null" (ruling out effects >3 arrests per 100,000), but the confidence intervals are wide. The authors should:
     - Report minimum detectable effects (MDEs) to contextualize the precision of the null result.
     - Discuss whether the sample size (51 border counties) is sufficient to detect plausible spillovers, given the heterogeneity in border enforcement (e.g., major ports vs. rural crossings).

---

### 4. **Suggestions**

#### **Conceptual and Interpretive Improvements**
1. **Clarify the scope of the null result**:
   - The paper claims "no enforcement externality," but the outcome (drug arrests) is a noisy proxy for both enforcement effort and drug activity. The authors should:
     - Explicitly state that the null result applies to *recorded* enforcement activity, not underlying drug markets or social harms.
     - Discuss whether legalization might have reduced enforcement effort (e.g., reallocating resources to other crimes) while increasing drug activity, yielding a net null in arrests.

2. **Strengthen the COVID diagnostic**:
   - The three-regime design is a strength, but the interpretation is cursory. The authors should:
     - Formalize the mechanism test: If spillovers operate through cross-border trafficking, the post-legalization coefficient should be positive, attenuate during COVID, and rebound post-reopening. The observed pattern (negative post-legalization, positive during/post-COVID) suggests alternative mechanisms (e.g., domestic trafficking, enforcement substitution).
     - Test whether the COVID closure differentially affected border counties with high pre-legalization crossing volumes (using BTS data).

3. **Address alternative explanations for the null**:
   - The null could reflect:
     - **No spillovers**: Legalization had no effect on US drug markets.
     - **Offsetting effects**: Increased trafficking was offset by reduced enforcement effort.
     - **Measurement error**: UCR data may not capture cross-border enforcement (e.g., federal arrests are excluded).
   - The authors should discuss these possibilities and suggest future work (e.g., using federal arrest data or survey-based drug use measures).

#### **Empirical and Robustness Improvements**
4. **Expand the sample**:
   - Re-estimate the main specification including all 12 border states (even those with partial legalization). This would:
     - Test whether spillovers differ in states with pre-existing legal markets.
     - Increase sample size and power.
   - Report results separately for states with/without legalization to assess heterogeneity.

5. **Improve precision**:
   - Report minimum detectable effects (MDEs) for the main specification, using the approach in \citet{lee2021}. This would help readers assess whether the study is powered to detect plausible spillovers.
   - Consider alternative clustering (e.g., county-level) or wild bootstrap standard errors to address the small number of state clusters (8).

6. **Leverage crossing volume data**:
   - The paper uses BTS crossing data to construct a continuous exposure measure (Column 3 of Table 1), but the results are not discussed. The authors should:
     - Interpret the exposure coefficients (e.g., do counties with higher crossing volumes experience larger spillovers?).
     - Test whether the COVID closure differentially affected high-volume ports.

7. **Test additional outcomes**:
   - The manifest proposed property crime and DUI as outcomes. While drug arrests are the most direct measure, the authors should:
     - Report results for property crime and DUI in an appendix to rule out spillovers in related outcomes.
     - Test whether legalization affected arrests for other drugs (e.g., opioids), which might substitute for cannabis.

8. **Address UCR reporting transitions**:
   - The paper notes that some agencies transitioned from SRS to NIBRS during the sample period. While the reporting-population normalization is a strength, the authors should:
     - Report results restricting to agencies that never transitioned (if feasible).
     - Test whether the null result holds for agencies that transitioned pre- vs. post-legalization.

#### **Presentation and Clarity**
9. **Improve table readability**:
   - Table 1 (main results) is dense and hard to parse. Suggestions:
     - Split into two tables: one for the main DiD results (Columns 1–2) and one for robustness (Columns 3–4).
     - Add a column with pre-period means to contextualize effect sizes.
     - Use stars or bold to highlight key coefficients (e.g., Border × Post-Legal).

10. **Clarify the event study**:
    - The event study (Figure 1) is critical for assessing parallel trends but is not shown in the paper. The authors should:
      - Include the event study plot in the main text (not just the appendix).
      - Add a placebo line (e.g., a fake treatment date) to the plot to demonstrate pre-trends.

11. **Discuss external validity**:
    - The paper focuses on the US-Canada border, but the results may not generalize to other contexts (e.g., US-Mexico, EU borders). The authors should:
      - Discuss how border enforcement intensity (e.g., staffing, surveillance) might moderate spillovers.
      - Speculate on whether the null result would hold for harder drugs (e.g., cocaine, opioids).

12. **Engage with the literature on border effects**:
    - The paper cites domestic cannabis studies but does not engage with the broader literature on cross-border spillovers (e.g., \citet{delacroix2020} on alcohol, \citet{ferrie2021} on migration). The authors should:
      - Discuss how their results compare to other cross-border policy studies.
      - Highlight the unique features of the US-Canada border (e.g., staffed ports, low smuggling incentives for cannabis).

#### **Minor Suggestions**
13. **Clarify the "bounded null" claim**:
    - The abstract states that the 95% CI rules out spillovers >3 arrests per 100,000, but this is not emphasized in the text. The authors should:
      - Add a sentence in the results section explicitly stating the upper bound of the CI.
      - Discuss whether 3 arrests per 100,000 is a policy-relevant threshold.

14. **Address the population-weighted results**:
    - The population-weighted specification yields a significant negative effect, but the authors dismiss it as driven by New York. This should be:
      - Acknowledged in the abstract (e.g., "population-weighted results are sensitive to New York").
      - Explored further (e.g., why does NY differ? Is it due to crossing volumes or enforcement practices?).

15. **Improve the conclusion**:
    - The conclusion is concise but could better highlight the paper’s broader implications. The authors should:
      - Emphasize that the null result suggests legalization is "containable" along well-monitored borders.
      - Discuss whether the findings support independent vs. coordinated international drug policy.

---

### **Final Assessment**
This is a well-executed paper that makes a novel and policy-relevant contribution. The identification strategy is sound, the data are appropriate, and the robustness checks are thorough. The null result is credible and bounded, ruling out meaningful positive spillovers. With the suggested improvements—particularly to the mechanism discussion, sample representativeness, and precision—the paper would be suitable for publication in *AER: Insights*. The authors should address the three essential points above before resubmission.
