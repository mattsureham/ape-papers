# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant B)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** B
**Date:** 2026-03-24T20:13:00.613240

---

# Referee Report

**Paper:** The Warning Paradox: NWS Office Boundaries and Tornado Casualties
**Format:** AER: Insights

## 1. Idea Fidelity

The paper adheres closely to the original idea manifest. It successfully operationalizes the proposed spatial discontinuity design, exploiting the arbitrary assignment of counties to National Weather Service (NWS) Weather Forecast Offices (WFOs). The core identification strategy—comparing adjacent counties across WFO boundaries—matches the manifest's proposal for a spatial RDD. The data sources (NOAA Storm Events, IEM Cow API) align with the feasibility check, though the sample period is 2008–2024 rather than the proposed 2008–2025 (a minor limitation given data availability). The paper also includes the suggested falsification tests (property damage, EF-scale) and the welfare calculation using Value of Statistical Life (VSL). One deviation is the treatment variable: the manifest suggested exploiting variation in warning quality, while the paper focuses specifically on *average lead time* as the continuous treatment, which is a valid narrowing of the scope for an Insights piece. Overall, the execution faithfully reflects the proposed research design.

## 2. Summary

This paper provides a novel quasi-experimental test of whether tornado warning lead times causally reduce casualties. By exploiting administrative boundaries between Weather Forecast Offices, the author finds that higher average lead times are associated with *increased* casualties, contradicting the prevailing meteorological literature. The author attributes this counter-intuitive result to a "detection-response trade-off," where aggressive early warning increases false alarms and erodes public compliance (the "cry wolf" effect). If valid, this finding has significant implications for how the NWS evaluates forecast office performance.

## 3. Essential Points

The paper presents a provocative and potentially high-impact finding, but three critical issues must be addressed to sustain the causal claim:

1.  **Endogeneity of WFO Performance Metrics:** While WFO *boundaries* are exogenous, WFO *performance* (lead time) is not randomly assigned. Offices with longer lead times may serve regions with fundamentally different storm morphologies (e.g., supercells vs. quasi-linear convective systems) that persist across boundaries. Even with boundary-pair fixed effects, if one side of a boundary systematically faces more "warnable" storm types that are also more deadly, the coefficient on lead time will be biased upward. The author must demonstrate that storm type composition is balanced across boundaries or control for it explicitly.
2.  **Weak Mechanism Evidence:** The central argument relies on the "cry wolf" effect (false alarms eroding compliance). However, in Table 3, the False Alarm Ratio (FAR) is statistically insignificant when included alongside lead time (Column 3). If false alarms are the mechanism driving the positive lead time coefficient, FAR should retain explanatory power. The current results suggest lead time is capturing something else, or the power to detect the FAR effect is too low. The mechanism claim is currently overstated relative to the evidence.
3.  **Treatment Measurement Error:** The treatment is the *long-run average* lead time of the WFO, not the realized lead time for the specific tornado event. This aggregates away within-office variation. If high-performing offices have lower variance in lead time, this measure conflates average speed with consistency. Furthermore, using a long-run average assumes that residents' compliance behavior is driven by historical office performance rather than the specific warning received. This attenuation bias complicates the magnitude interpretation of the 0.054 coefficient.

## 4. Suggestions

The following recommendations are intended to strengthen the empirical strategy, clarify the mechanism, and tailor the manuscript for the *AER: Insights* format. These suggestions constitute the primary path to publication.

### A. Strengthening the Identification Strategy

**1. Visualize the Discontinuity:**
For a spatial discontinuity design, visual evidence is crucial. Please add a bin-scatter plot showing average casualties (y-axis) against distance to the WFO boundary (x-axis), separately for counties on either side. Overlay the difference in average lead time across the boundary. This will allow readers to visually inspect whether the jump in casualties coincides with the jump in lead time at the boundary. If the relationship is smooth across the boundary except for the WFO switch, confidence in the design will increase substantially.

**2. Control for Storm Morphology:**
To address the endogeneity of performance metrics, you should control for storm type. The Storm Prediction Center (SPC) data often includes flags for "supercell" vs. "QLCS" (Quasi-Linear Convective System) or similar distinctions in the storm attributes. Supercells typically allow for longer lead times but are also more violent. Even if EF-scale is controlled, the *type* of storm affects both warnability and damage potential.
*   *Action:* Interact EF-scale with path width/length, or include storm type dummies if available. Alternatively, restrict the sample to only EF2+ events where storm structure is more consistent, or only QLCS events where lead times are notoriously short, to see if the effect persists within homogeneous storm types.

**3. Bandwidth Sensitivity:**
The current design uses all boundary pairs. A strict Spatial RDD would limit the sample to counties within a specific distance (e.g., 10km, 20km) of the boundary.
*   *Action:* Re-estimate the main specification restricting the sample to counties within 10, 20, and 50 kilometers of the WFO boundary. If the coefficient remains stable as the bandwidth narrows, this provides strong evidence that unobserved geographic confounders are not driving the result. Report these in an appendix table.

### B. Clarifying the Mechanism

**4. Construct a County-Level False Alarm History:**
The current test uses WFO-level FAR. However, the "cry wolf" effect is likely local. Residents in a county on the edge of a WFO might experience different false alarm rates than the WFO average.
*   *Action:* Construct a county-specific cumulative false alarm measure (e.g., number of false warnings issued for that county in the prior 12 months). Interact this with the WFO lead time. If the positive lead time effect is driven by false alarms, it should be strongest in counties with high recent false alarm history. This would provide direct evidence for the behavioral channel.

**5. Alternative Mechanism: Warning Fatigue vs. Lead Time:**
Consider that longer lead times might correlate with *more* warnings issued overall (not just false ones). If an office warns aggressively, they might issue more warnings for marginal events.
*   *Action:* Check if WFOs with higher average lead time also have higher warning *frequency* per tornado event. If so, the effect might be warning fatigue rather than false alarm credibility. Distinguishing these helps refine the policy recommendation.

**6. Re-evaluate the FAR Coefficient:**
The insignificance of FAR in Table 3 is troubling for the narrative.
*   *Action:* Check for multicollinearity between Lead Time and FAR. If they are highly correlated, report the Variance Inflation Factor (VIF). Consider using the Critical Success Index (CSI) as the primary alternative metric rather than FAR alone, as CSI is the metric NWS actually monitors. If CSI shows a negative (protective) effect while Lead Time shows a positive (harmful) effect, frame the result as "Lead Time vs. Precision" rather than "Lead Time vs. False Alarms."

### C. Data and Measurement Refinements

**7. Treatment Definition:**
The use of long-run average lead time is a "shift-share" style instrument. Be precise about the interpretation.
*   *Action:* In the text, clarify that you are estimating the effect of being assigned to a *type* of office, not the effect of a specific minute of warning. Consider a two-stage least squares (2SLS) approach where the "assigned WFO" instruments for the realized lead time, though this may be noisy. At minimum, discuss the attenuation bias explicitly: if anything, the true effect of realized lead time is likely larger in magnitude than your estimate suggests.

**8. Sample Selection Flow:**
The manifest proposed ~27,000 events; the paper uses 21,346.
*   *Action:* Add a flow chart or detailed note explaining the attrition. How many events were dropped because they occurred in non-boundary counties? How many boundary pairs were inactive? Transparency here ensures readers understand the external validity of the sample (i.e., are boundary counties representative of the US overall?).

**9. Zero-Inflated Outcomes:**
Casualty data is highly zero-inflated (94% of events have no casualties). The paper uses OLS.
*   *Action:* While OLS with FE is standard for linear probability models, consider a Poisson or Negative Binomial model for the count data (as mentioned in robustness) as a primary specification for casualties. Report the Incidence Rate Ratio (IRR). This handles the skewness of the dependent variable more appropriately than OLS.

### D. Presentation and Policy Implications

**10. Tailoring for AER: Insights:**
*AER: Insights* papers are typically concise (4,000–5,000 words) and focus on a single clear message.
*   *Action:* Tighten the Introduction and Institutional Background. The current draft is slightly long. Move the detailed data construction to an online appendix. Focus the main text on the paradox (Lead Time $\uparrow$ = Casualties $\uparrow$) and the policy implication. Ensure the abstract clearly states the identification strategy (boundary FE) in the first sentence.

**11. Nuance the Policy Conclusion:**
The conclusion suggests shifting from lead time to precision. This is actionable, but be careful not to imply lead time is worthless.
*   *Action:* Refine the policy recommendation. Suggest a *composite* metric (like CSI) rather than abandoning lead time entirely. Acknowledge that lead time is still valuable *if* false alarms are held constant. The key insight is the trade-off, not the uselessness of lead time. This makes the advice more palatable to the NWS community.

**12. Replication Package:**
Given the novelty of the data merge (SPC + IEM + Census + Shapefiles), reproducibility is key.
*   *Action:* Explicitly state in the footnote or data section that the code and merged data will be made available on the AER website or GitHub. Provide the specific variable names used from the IEM Cow API to ensure others can replicate the WFO performance metrics exactly.

### E. Minor Corrections

*   **Table 1:** The mean casualties per event is 0.449, but the "Any casualty" mean is 0.060. This implies that when casualties occur, they are clustered (average ~7.5 casualties per event with casualties). Mention this clustering in the text; it affects the interpretation of the coefficient.
*   **Table 3:** Column 5 (CSI) coefficient is negative but insignificant. In the text, you describe it as "in the expected direction." Be careful not to over-interpret insignificant coefficients. Use phrases like "point estimates suggest" rather than "CSI carries a negative coefficient."
*   **References:** Ensure all citations (e.g., `simmons2005`, `uccellini2019`) are fully detailed in the bibliography. The LaTeX source shows placeholders; these must be resolved for submission.
*   **Formatting:** The current LaTeX template is a standard article. Ensure you switch to the official *AER: Insights* template if accepted, but for review, ensure margins and spacing meet standard journal readability (current 1.5 spacing is fine).

By addressing the endogeneity of storm types, providing stronger visual evidence of the discontinuity, and nuancing the mechanism regarding false alarms, this paper has the potential to be a landmark study in the economics of disaster policy. The core idea is excellent; the execution requires only rigorous tightening to meet the high bar for causal inference.
