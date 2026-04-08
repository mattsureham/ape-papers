# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-04-08T10:16:56.915977
**Route:** Direct Google API + PDF
**Tokens:** 18917 in / 2003 out
**Response SHA256:** 5aaccca4885d5798

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics"
**Page:** 10
- **Formatting:** Clean and professional. Use of horizontal rules is appropriate (top, middle, bottom). Panel A and Panel B are clearly distinguished. 
- **Clarity:** Logical grouping. Decimal places are consistent within rows, though "Total Cost" has two decimals while "Normalized Cost" has two, which is fine given the scales.
- **Storytelling:** Essential. It sets the scene for the full sample versus the RDD estimation sample.
- **Labeling:** The note is comprehensive, explaining the data source and the measurement window.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Distribution of Pipeline Incidents by Normalized Cost"
**Page:** 10
- **Formatting:** Good use of a histogram with an overlaid threshold marker. The truncation note is vital.
- **Clarity:** Very high. The reader immediately sees where the identifying variation lies.
- **Storytelling:** Supports the validity of the RDD by showing a "well-populated" region around the cutoff.
- **Labeling:** X-axis is clear. The red dashed line "Significant threshold" is well-placed.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "McCrary Density Test at the Significant Incident Threshold"
**Page:** 14
- **Formatting:** Professional ggplot-style output. Shaded CIs are standard.
- **Clarity:** The binning is a bit noisy, but the smoothed lines make the message clear.
- **Storytelling:** Mandatory for RDD papers in top journals to address manipulation.
- **Labeling:** Title and notes are descriptive.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "First Stage: Significant Incident Label by Normalized Cost"
**Page:** 15
- **Formatting:** Clean. Point sizes proportional to bin counts is an excellent touch (standard in *Econometrica* or *QJE*).
- **Clarity:** The jump is undeniable. 
- **Storytelling:** Establishes the "near-perfect" first stage mentioned in the abstract.
- **Labeling:** Y-axis clearly labeled with percentage units.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Covariate Balance: Cause Distribution Near Threshold"
**Page:** 16
- **Formatting:** Bar chart is clean. Colors (Above/Below) are distinguishable.
- **Clarity:** Slightly cluttered due to the long category names on the x-axis.
- **Storytelling:** Crucial for showing that incident "physics" don't jump at the cost threshold.
- **Labeling:** Axis labels are clear, but category labels are angled; consider horizontal labels if names were shortened (e.g., "Corrosion", "Excavation").
- **Recommendation:** **REVISE**
  - Shorten the category names (e.g., "Material Failure" instead of "Material Failure of Pipe or Weld") to allow for horizontal text on the x-axis, which is easier to read.

### Figure 5: "RD Plot: Effect of Significant Label on Future Incidents (t+1 to t+3)"
**Page:** 17
- **Formatting:** Standard RD plot.
- **Clarity:** The bin means (points) are very scattered, which visually emphasizes the "null" result but also the lack of power.
- **Storytelling:** The core result. It shows no discontinuity.
- **Labeling:** Axis labels are correct.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Effect of Significant Incident Label on Future Pipeline Safety"
**Page:** 17
- **Formatting:** Journal-ready. SEs in parentheses, CIs in brackets.
- **Clarity:** Logic of columns (1-4) is clear. 
- **Storytelling:** The primary evidence table.
- **Labeling:** Clear notes. "N (left/right)" is very helpful for RDD papers. 
- **Recommendation:** **REVISE**
  - Add significance stars even if none are present (state "Significance levels: * p<0.1, ** p<0.05, *** p<0.01" in notes) to conform to journal style.
  - Align columns by decimal point for the coefficients.

### Figure 6: "Bandwidth Sensitivity of the Main RD Estimate"
**Page:** 19
- **Formatting:** Clean coefficient plot. 
- **Clarity:** Easy to see the convergence toward zero as bandwidth grows.
- **Storytelling:** Important robustness check.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**
  - Table 3 provides the exact same information with more precision. The figure is helpful but takes up significant main-text real estate for a robustness check.

### Table 3: "Bandwidth Sensitivity"
**Page:** 19
- **Formatting:** Standard.
- **Clarity:** Good.
- **Storytelling:** Supplements Figure 6.
- **Labeling:** Professional.
- **Recommendation:** **KEEP AS-IS**

### Figure 7: "Placebo Threshold Tests"
**Page:** 20
- **Formatting:** Good use of color to highlight the true threshold.
- **Clarity:** Very high.
- **Storytelling:** Strengthens the causal claim.
- **Labeling:** Axis labels are clear.
- **Recommendation:** **MOVE TO APPENDIX**
  - While strong, placebos are secondary to the main results and can live in the appendix to tighten the main narrative.

### Figure 8: "RD Plot: Effect of Significant Label on Future Incident Costs (log)"
**Page:** 22
- **Formatting:** Consistent with Figure 5.
- **Clarity:** The fit lines are quite "wiggly," suggesting a high-order polynomial or overfitting.
- **Storytelling:** Shows the null extends to the intensive margin.
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - Use a simpler linear or quadratic fit for the visual lines. The current high-order curves look like they are "chasing noise," which can be a red flag for reviewers.

---

## Appendix Exhibits

### Figure 9: "Appendix: Bandwidth Sensitivity (Reproduction)"
**Page:** 32
- **Formatting:** Identical to Fig 6.
- **Clarity:** Good.
- **Storytelling:** Redundant if Figure 6 is moved here.
- **Labeling:** Clear.
- **Recommendation:** **REMOVE**
  - Redundant reproduction of Figure 6.

### Table 4: "Standardized Effect Sizes"
**Page:** 33
- **Formatting:** Extremely dense notes. The table itself is clean.
- **Clarity:** High.
- **Storytelling:** Helps address the "power" concern by showing magnitudes.
- **Labeling:** "Classification" column is a bit non-standard for top journals; usually, authors let the SDE speak for itself.
- **Recommendation:** **REVISE**
  - Trim the notes. Much of the "Policy mechanism" and "Outcome definition" text is already in the main body. Stick to technical notes for the table.

---

## Overall Assessment

- **Exhibit count:** 3 main tables, 8 main figures, 1 appendix table, 1 appendix figure.
- **General quality:** High. The paper follows RDD best practices for visual presentation (First stage, McCrary, Balance, Sensitivity).
- **Strongest exhibits:** Figure 3 (First Stage) and Table 1 (Summary Stats).
- **Weakest exhibits:** Figure 8 (over-fitted RD lines) and Figure 4 (cramped x-axis).
- **Missing exhibits:** 
    - **Operator Size Heterogeneity Table:** The text mentions that splitting the sample by operator size reveals no heterogeneity, but this should be a standalone table (or a panel in Table 2) rather than just being tucked into the SDE table in the appendix.
    - **A Table of "Substantive Consequences":** The paper argues the label doesn't work because it's "soft." A table showing that "Significant" incidents don't actually lead to much higher fines compared to "Non-significant" (at the margin) would provide the "smoking gun" for the mechanism.

**Top 3 improvements:**
1. **Streamline the Main Text:** Move Figure 6 (Bandwidth) and Figure 7 (Placebos) to the Appendix. They are standard checks but clutter the results section.
2. **Fix RD Plot Visualization:** In Figure 8 (and Figure 5), use lower-order polynomials for the fit lines. High-degree polynomials at the threshold are often criticized by reviewers for creating "illusory" fits.
3. **Enhance Mechanism Evidence:** Create a new Table or Figure showing the "Second Stage" of the regulator's response (e.g., probability of a fine or fine amount) at the threshold to prove that the "name-and-shame" is truly isolated from "substantive" punishment.