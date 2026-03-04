# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-04T14:16:35.114661
**Route:** Direct Google API + PDF
**Tokens:** 30357 in / 2235 out
**Response SHA256:** 65880d75e0826617

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Figure 1: "Population-Weighted Network Minimum Wage Exposure by County"
**Page:** 12
- **Formatting:** High quality. The color ramp is intuitive (darker = higher exposure). The projection is standard and professional.
- **Clarity:** Clear. It effectively demonstrates the "within-state" variation crucial for the identification strategy (e.g., look at the variation within Texas).
- **Storytelling:** Strong. It sets the stage for why this specific weighting (population) creates variation that simple geography doesn't.
- **Labeling:** Legend is clear with units ($). Subtitle provides necessary context.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Population-Weighted Minus Probability-Weighted Exposure Gap"
**Page:** 13
- **Formatting:** Diverging color scale (Blue/Red) is appropriate for a difference map.
- **Clarity:** Good. The contrast between coastal-connected counties and rural-connected counties is immediate.
- **Storytelling:** Vital for the paper's "Scale vs. Share" argument. It justifies why Equation (2) differs from Equation (1).
- **Labeling:** Legend correctly uses "Gap ($)".
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Within-State Residual Variation in the Instrumental Variable"
**Page:** 14
- **Formatting:** Clean two-panel layout.
- **Clarity:** The residuals are centered at zero, which is correct for demonstrating variation after fixed effects.
- **Storytelling:** This is a "visual first stage/identification" check. It proves the IV isn't just picking up state-level trends.
- **Labeling:** Legend "Residual IV" is technically correct but perhaps "Instrument Residuals" is more reader-friendly. 
- **Recommendation:** **REVISE**
  - Increase the font size of "Panel A" and "Panel B" to match top journal styles (AER/QJE).

### Table 1: "Network Minimum Wage Exposure and Local Labor Market Outcomes"
**Page:** 37
- **Formatting:** Excellent. Professional horizontal rules, no vertical lines. Panel A/B structure is perfect.
- **Clarity:** Logical progression from OLS to 2SLS to distance restrictions.
- **Storytelling:** This is the "money table." It shows the monotonic increase with distance, which is a powerful defense against local confounders.
- **Labeling:** Stars defined, standard errors in parentheses, and a very thorough note.
- **Recommendation:** **KEEP AS-IS** (This is a model of a top-journal table).

### Table 2: "USD-Denominated Specifications: 2SLS Estimates"
**Page:** 38
- **Formatting:** Consistent with Table 1.
- **Clarity:** High. Converting to dollars makes the magnitudes ($1 increase = 9% emp) "headline-ready."
- **Storytelling:** Essential for economic significance.
- **Labeling:** Notes explain the standard deviation shift context.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Balance Tests: Pre-Period Characteristics by IV Quartile"
**Page:** 38
- **Formatting:** Good.
- **Clarity:** Clear presentation of the F-test for equality.
- **Storytelling:** Honest. It shows there *is* imbalance in levels (absorbed by FE), which the authors discuss.
- **Labeling:** Units (logs) are clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "First Stage: Out-of-State vs. Full Network Exposure"
**Page:** 18
- **Formatting:** Standard binscatter. Red fit line and confidence interval are clear.
- **Clarity:** Extremely high. 
- **Storytelling:** Visual proof of a "massive" first stage. 
- **Labeling:** Slope and F-stat are included in the plot area, which is standard.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Distance-Credibility Tradeoff"
**Page:** 21
- **Formatting:** Dual-axis plot.
- **Clarity:** A bit busy. The crossing lines are the point, but dual-axes (left for F-stat, right for p-value) can be tricky.
- **Storytelling:** One of the most important conceptual figures. It justifies why the authors focus on the "middle" distance thresholds.
- **Labeling:** "RF Pre-Trend p" and "Balance p" are clearly distinguished.
- **Recommendation:** **REVISE**
  - Add a vertical shaded region or arrow indicating the "Sweet Spot" (100–250km) mentioned in the text.

### Figure 6: "Event Study: Employment Response to Network Exposure"
**Page:** 39
- **Formatting:** Clean. Reference year (2013) is clearly marked by the dot at zero.
- **Clarity:** Good use of colors.
- **Storytelling:** Establishes the timing. Effects only appear when the "Fight for $15" policies actually start moving.
- **Labeling:** Shaded region correctly identified as 95% CI.
- **Recommendation:** **KEEP AS-IS**

### Figure 7: "Structural vs. Reduced-Form Event Studies"
**Page:** 40
- **Formatting:** High-frequency (quarterly) dots make it look a bit "noisy" compared to Figure 6.
- **Clarity:** The comparison is clear, but the y-axis scales differ significantly.
- **Storytelling:** Confirms the IV isn't creating the dynamic shape.
- **Recommendation:** **MOVE TO APPENDIX**
  - Figure 6 already tells the main story. This is a technical check that belongs in the robustness section.

### Figure 8: "Pre-Treatment Employment Trends by IV Quartile"
**Page:** 41
- **Formatting:** Standard trend plot.
- **Clarity:** Shows the "Parallel-ish" trends despite level differences.
- **Storytelling:** Crucial for the DiD-style logic of the shift-share.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Shock-Robust Inference"
**Page:** 41
- **Formatting:** Clean.
- **Clarity:** Compares different SE clustering methods.
- **Storytelling:** Pure robustness.
- **Recommendation:** **MOVE TO APPENDIX**
  - This is too technical for the main flow. A single sentence in the text ("Results are robust to network and state-level clustering") is sufficient if the table is in the appendix.

### Table 5: "Job Flow Mechanism: Effects of Network Exposure on Labor Market Dynamics"
**Page:** 42
- **Formatting:** Panel structure within the table is clean.
- **Clarity:** Shows Hires vs. Separations vs. Net Creation.
- **Storytelling:** Key to the "Information Channel" argument—proving it's churn, not just more jobs.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Migration Mechanism Tests: IRS County-to-County Flows"
**Page:** 42
- **Formatting:** Consistent.
- **Clarity:** Shows nulls effectively.
- **Storytelling:** Vital to rule out the "People moved to where the money was" explanation.
- **Recommendation:** **KEEP AS-IS** (Or consolidate with Table 5 if space is tight).

---

## Appendix Exhibits

### Figure 9: "Net Migration by Network Exposure Quartile, 2012–2019"
**Page:** 43
- **Recommendation:** **KEEP AS-IS**
- **Comment:** Good supporting evidence for Table 6.

### Table 7: "Policy Diffusion: Network Exposure and Future Minimum Wage Changes"
**Page:** 44
- **Recommendation:** **PROMOTE TO MAIN TEXT**
- **Comment:** This addresses a major endogeneity concern (political feedback). In an AER/JPE paper, ruling out the "Policy Diffusion" channel is a first-order concern, not a footnote.

### Figure 10: "Heterogeneity by Census Division"
**Page:** 45
- **Recommendation:** **KEEP AS-IS**
- **Comment:** Excellent coefficient plot. The "South vs. New England" contrast is a powerful mechanism check.

### Table 8: "Distance-Credibility Analysis"
**Page:** 48
- **Recommendation:** **KEEP AS-IS**
- **Comment:** This is the raw data for Figure 5. Correct to place in Appendix.

### Table 11: "Robustness: Sample Restrictions"
**Page:** 50
- **Recommendation:** **REVISE**
  - Consolidate Table 11 and Table 12 (Leave-One-State-Out) into a single "Robustness Summary" table to save reader "table-fatigue."

---

## Overall Assessment

- **Exhibit count:** 7 main tables, 7 main figures, 8 appendix tables, 2 appendix figures.
- **General quality:** Extremely high. The paper follows the "Bailey/Stroebel" school of SCI visualization, which is current best-practice for top-5 journals.
- **Strongest exhibits:** Table 1 (The definitive results table) and Figure 10 (Geographic heterogeneity).
- **Weakest exhibits:** Figure 7 (Too noisy/redundant) and Figure 5 (Dual-axis complexity).
- **Missing exhibits:** A **Summary Statistics** table. Readers need to know the mean/SD of "Network MW" and "County Earnings" before seeing the regression coefficients.
- **Top 3 improvements:**
  1. **Add a Summary Statistics table** at the start of the Data section.
  2. **Promote Table 7 (Policy Diffusion)** to the main text; it is too important for identification to be buried in the appendix.
  3. **Consolidate Robustness:** Merge the various sample restriction and leave-out tables (11, 12, 14) into one or two more concise exhibits.