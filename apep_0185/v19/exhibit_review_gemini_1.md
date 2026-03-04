# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-04T22:05:44.280332
**Route:** Direct Google API + PDF
**Tokens:** 28797 in / 2423 out
**Response SHA256:** e8ca199fb8330818

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Figure 1: "Population-Weighted Network Minimum Wage Exposure by County"
**Page:** 12
- **Formatting:** Professional. The color ramp is clear and the legend is well-positioned. 
- **Clarity:** Good. It effectively shows the "treatment" variation. However, the "darker = stronger" text is a bit small.
- **Storytelling:** Essential. It establishes the spatial variation that drives the shift-share design.
- **Labeling:** Clear. Units ($) are included in the legend.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Population-Weighted Minus Probability-Weighted Exposure Gap"
**Page:** 13
- **Formatting:** Standard choropleth map. The diverging red-blue scale is appropriate for a difference map.
- **Clarity:** High. Shows exactly where the population-weighting innovation matters most (California-Texas corridor).
- **Storytelling:** Very strong. This justifies the "scale of connections" argument visually.
- **Labeling:** Legend is clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Within-State Residual Variation in the Instrumental Variable"
**Page:** 14
- **Formatting:** Multi-panel layout is good. 
- **Clarity:** Crucial for identification. It proves there is variation remaining after state-time fixed effects. 
- **Storytelling:** Excellent. It directly addresses the "how do you have variation if you have state-time FEs?" question.
- **Labeling:** Sub-titles for Panel A and B are helpful.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "First Stage: Out-of-State vs. Full Network Exposure"
**Page:** 18
- **Formatting:** High-quality binscatter. The regression line and confidence interval are visible.
- **Clarity:** The slope and F-stat are printed directly on the plot, making the message instant.
- **Storytelling:** Standard but necessary to prove instrument relevance.
- **Labeling:** Axis labels are descriptive (log MW).
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Distance-Credibility Tradeoff"
**Page:** 21
- **Formatting:** A dual-axis plot. Dual-axis plots are often discouraged in top journals (AER/QJE), but here it effectively shows the "sweet spot."
- **Clarity:** Good use of colors (blue for strength, red for balance).
- **Storytelling:** High impact. It visualizes the trade-off described in the text.
- **Labeling:** Clear legend at the bottom.
- **Recommendation:** **REVISE**
  - Consider making the y-axis labels larger.
  - Check if a two-panel vertical plot (top: F-stat, bottom: p-value) would be cleaner than a dual-axis plot, as dual-axes can be misleading.

### Figure 6: "Pre-Treatment Employment Trends by IV Quartile"
**Page:** 22
- **Formatting:** Professional line chart. 
- **Clarity:** Clear parallel trends before 2014.
- **Storytelling:** Mandatory for any DiD-style or shift-share paper to prove pre-trends are parallel.
- **Labeling:** Legend is descriptive.
- **Recommendation:** **KEEP AS-IS**

### Figure 7: "Net Migration by Network Exposure Quartile, 2012–2019"
**Page:** 26
- **Formatting:** Consistent with Figure 6.
- **Clarity:** Clearly shows the null result for migration.
- **Storytelling:** Essential for the "information not migration" mechanism.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

### Figure 8: "Heterogeneity in Network Exposure Effects by Census Division"
**Page:** 28
- **Formatting:** Clean coefficient plot with 95% CIs.
- **Clarity:** Very high. The ordering (from smallest to largest effect) helps the reader.
- **Storytelling:** Strong. Supports the theory that effects are larger where the "wage gap" is larger (the South).
- **Labeling:** The "Overall OLS" red line is a helpful benchmark.
- **Recommendation:** **KEEP AS-IS**

### Table 1: "Network Minimum Wage Exposure and Local Labor Market Outcomes"
**Page:** 39
- **Formatting:** Professional AER/QJE style. Three-line border. Standard errors in parentheses. Significance stars used.
- **Clarity:** Logical progression from OLS to 2SLS to distance-restricted.
- **Storytelling:** This is the "money table." It summarizes the whole paper. 
- **Labeling:** Comprehensive notes section.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "USD-Denominated Specifications: 2SLS Estimates"
**Page:** 40
- **Formatting:** Clean and focused.
- **Clarity:** Translates logs into dollars, which is more intuitive for readers.
- **Storytelling:** Highly helpful for the "Discussion" section to talk about the 9% employment magnitude.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Shock Contribution Diagnostics"
**Page:** 40
- **Formatting:** Clean.
- **Clarity:** Shows which states drive the results. 
- **Storytelling:** Essential for shift-share (Goldsmith-Pinkham/Borusyak) transparency.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Balance Tests: Pre-Period Characteristics by IV Quartile"
**Page:** 41
- **Formatting:** Standard balance table.
- **Clarity:** Good.
- **Storytelling:** Necessary to show potential confounders.
- **Labeling:** Standard deviations in parentheses correctly noted.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Shock-Robust Inference"
**Page:** 41
- **Formatting:** Clean.
- **Clarity:** Proves that the significance isn't an artifact of how errors are clustered.
- **Storytelling:** High importance for Econometrica/ReStud audiences interested in econometrics.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Job Flow Mechanism: Effects of Network Exposure on Labor Market Dynamics"
**Page:** 42
- **Formatting:** Professional.
- **Clarity:** Compares OLS to 2SLS across many outcomes.
- **Storytelling:** Crucial for the "Churn/Dynamism" mechanism.
- **Labeling:** Notes mention confidentiality suppression (explaining the N variation).
- **Recommendation:** **KEEP AS-IS**

### Table 7: "Migration Mechanism Tests: IRS County-to-County Flows"
**Page:** 42
- **Formatting:** Consistent with Table 6.
- **Clarity:** Confirms the null on migration.
- **Storytelling:** Redundant? The figure (Fig 7) is much more powerful. 
- **Recommendation:** **MOVE TO APPENDIX**
  - The figure tells the story well enough for the main text. The table is supporting evidence.

### Table 8: "Policy Diffusion: Network Exposure and Future Minimum Wage Changes"
**Page:** 43
- **Formatting:** Standard.
- **Clarity:** Clear falsification test.
- **Storytelling:** Important to rule out political feedback.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Table 9: "Distance-Credibility Analysis: Instrument Strength, Balance, and Treatment Effects"
**Page:** 46
- **Recommendation:** **KEEP AS-IS** (Strong supporting table for Figure 5).

### Table 10: "LATE Complier Characterization..."
**Page:** 46
- **Recommendation:** **KEEP AS-IS**

### Table 11: "Robustness: Sample Restrictions (2SLS)"
**Page:** 47
- **Recommendation:** **KEEP AS-IS**

### Table 12: "Robustness: Leave-One-State-Out (2SLS)"
**Page:** 48
- **Recommendation:** **KEEP AS-IS**

### Table 13: "Placebo Instrument Tests"
**Page:** 49
- **Recommendation:** **KEEP AS-IS**

### Table 14: "Robustness: Alternative Controls (2SLS)"
**Page:** 50
- **Recommendation:** **KEEP AS-IS**

### Table 15: "Falsification: Placebo Network Exposures and MW Adoption"
**Page:** 51
- **Recommendation:** **KEEP AS-IS**

### Figure 9: "Policy Diffusion: Distance Monotonicity"
**Page:** 52
- **Recommendation:** **REVISE**
  - The y-axis scaling makes it look like there is a huge dip at 500km, but the confidence interval is massive. Ensure the y-axis (Coefficient) is labeled clearly.

### Figure 10: "Probability-Weighted Network Minimum Wage Exposure by County"
**Page:** 53
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 8 main tables, 8 main figures, 7 appendix tables, 2 appendix figures.
- **General quality:** Extremely high. This is one of the most visually polished working papers I've seen. The figures are high-resolution, color-blind friendly, and follow a consistent design language. Tables are strictly formatted to AER standards.
- **Strongest exhibits:** Table 1 (The definitive results table) and Figure 2 (The population-gap map).
- **Weakest exhibits:** Figure 5 (Dual-axis plots are controversial) and Table 7 (Redundant with Fig 7).
- **Missing exhibits:** A **Summary Statistics table** (Table 0) is missing. While Table 4 gives some pre-period means, a standard table showing Mean/SD/Min/Max for all main variables (Log Earnings, Log Employment, Network Exposure, Out-of-state Exposure) for the full regression sample is expected.

### Top 3 improvements:
1.  **Add a Summary Statistics Table:** Readers need to see the "lay of the land" (means and variances) for the actual regression sample before diving into coefficients.
2.  **Streamline Main Text Mechanism Evidence:** Move Table 7 to the Appendix. Figure 7 is sufficient and more intuitive for the main text.
3.  **Refine Figure 5:** Switch from a dual-axis plot to a vertically stacked two-panel plot. This avoids the "arbitrary scaling" criticism that top-tier reviewers often have for dual-axis charts.