# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-05T11:21:11.608016
**Route:** Direct Google API + PDF
**Tokens:** 20477 in / 1946 out
**Response SHA256:** d3c0a2c9e43289ac

---

As a visual exhibit advisor for top-tier economics journals, I have reviewed the 11 exhibits in your paper. Overall, the paper is technically proficient, but the visual presentation—particularly the figures—retains a "default software" look that would not meet the aesthetic standards of the AER or QJE.

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Hospitals Within ±10pp of 340B Threshold"
**Page:** 13
- **Formatting:** Clean layout. However, numbers are not decimal-aligned, which makes comparing standard deviations difficult.
- **Clarity:** Good. The split between "Below" and "Above" is logical.
- **Storytelling:** Strong. It establishes the baseline differences in the RDD window.
- **Labeling:** Clear. The note is comprehensive.
- **Recommendation:** **REVISE**
  - Decimal-align all numeric columns.
  - Add a "Difference" column (Above minus Below) with a t-test for balance. This is standard for RDD papers to show local randomization.

### Table 2: "Main RDD Results: Effect of 340B Eligibility on Drug Spending"
**Page:** 18
- **Formatting:** Professional. Good use of horizontal rules (booktabs style).
- **Clarity:** High. Grouping different outcomes in one table is efficient.
- **Storytelling:** This is the "money table." It cleanly shows the effect is specific to Medicaid drugs.
- **Labeling:** Excellent. Significance stars and standard error locations are noted.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Figure 1: "Distribution of Hospital DSH Adjustment Percentages"
**Page:** 33
- **Formatting:** The grey gridlines and background are too prominent. The red dashed line for the threshold is standard but a bit thin.
- **Clarity:** The x-axis labels are a bit crowded. 
- **Storytelling:** Essential for showing the running variable distribution. 
- **Labeling:** Good, but the "Number of Hospitals" y-axis could be formatted with commas for thousands (if applicable, though not here).
- **Recommendation:** **REVISE**
  - Use `theme_classic()` or `theme_bw()` to remove the grey background and gridlines.
  - Make the bars a lighter shade of grey or use a black outline to improve professional appearance.

### Figure 2: "McCrary Density Test at 340B Eligibility Threshold"
**Page:** 33
- **Formatting:** Default `rdrobust` output. Journals prefer a customized version that matches the rest of the paper’s aesthetic.
- **Clarity:** The p-value in the subtitle is small.
- **Storytelling:** Vital for validity.
- **Labeling:** Ensure the x-axis label matches the phrasing used in Figure 1 exactly.
- **Recommendation:** **REVISE**
  - Remove the default title and subtitle from the plot area; move this information into the Figure Note in the LaTeX source.
  - Change the red line to a solid black line or a more professional dark red.

### Figure 3: "RDD Plot: 340B Eligibility and Medicaid Drug Spending"
**Page:** 34
- **Formatting:** Too "stock." The gridlines and the large red line look like a basic R output.
- **Clarity:** The jump is visible, which is good.
- **Storytelling:** This is your primary visual evidence. It needs to be the most polished figure.
- **Labeling:** "Medicaid Drug Spending (asinh)" is clear.
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - This figure is too important for the appendix.
  - **Specific Revise:** Remove the grey gridlines. Use larger dots for the binned means. Change the fit lines to be slightly thicker. Ensure the y-axis range doesn't have excessive empty space.

### Figure 4: "RDD Plot: 340B Eligibility and Medicare Drug Spending"
**Page:** 35
- **Formatting:** Same issues as Figure 3 (grey background, default lines).
- **Clarity:** Shows the null effect well.
- **Storytelling:** This is the "Placebo" counterpart to Figure 3.
- **Recommendation:** **REVISE**
  - Match the styling changes of Figure 3 (no background, no gridlines).
  - Consider combining Figure 3 and Figure 4 into a single Figure with **Panel A (Medicaid)** and **Panel B (Medicare)**. This would be a powerful "AER-style" exhibit.

### Figure 5: "Bandwidth Sensitivity of RDD Estimates"
**Page:** 35
- **Formatting:** The blue shaded confidence interval is a bit "muddy."
- **Clarity:** The dashed line at 0 is essential and present.
- **Storytelling:** Standard robustness.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS** (after removing background gridlines).

### Figure 6: "Placebo Cutoff Tests"
**Page:** 36
- **Formatting:** Clean "forest plot" style.
- **Clarity:** The red dot for the true threshold is a great touch.
- **Storytelling:** Very convincing for RDD validity.
- **Recommendation:** **KEEP AS-IS**

### Figure 7: "Year-by-Year RDD Estimates"
**Page:** 36
- **Formatting:** The shaded CI is very wide, which is honest but visually distracting.
- **Clarity:** The x-axis is discrete years; a point-and-whisker plot might be cleaner than a line-and-ribbon.
- **Storytelling:** Important for discussing the 2020 COVID anomaly.
- **Recommendation:** **REVISE**
  - Switch from a "ribbon" to "error bars" (point-and-whisker). Line plots with ribbons often imply a continuous process, whereas these are distinct annual regressions.

### Figure 8: "Placebo: 340B Eligibility and Non-Drug Medicaid Spending"
**Page:** 37
- **Formatting:** Same aesthetic issues as Figures 3 and 4.
- **Clarity:** Shows the null well.
- **Recommendation:** **MOVE TO APPENDIX** (Already there, keep it there).

### Appendix Tables (B.3, C.1, C.2, C.3, C.4, C.5)
**Pages:** 31-32
- **Formatting:** These are "naked" tables without titles or proper headers. They look like raw LaTeX output.
- **Storytelling:** These are essential robustness checks but are currently under-formatted.
- **Recommendation:** **REVISE**
  - Give each table a proper "Table [X]: [Title]" and "Notes: ..." structure.
  - Consolidate: C.2 (Bandwidth), C.3 (Polynomial), and B.3 (Donut Hole) can likely be combined into one large "Robustness Table" with different panels.

---

# Overall Assessment

- **Exhibit count:** 2 main tables, 0 main figures, 7 appendix tables, 8 appendix figures.
- **General quality:** The tables are logically structured but the figures look like default `ggplot2` or `STATA` outputs. Top journals expect a "publication theme" (white background, no gridlines, high-contrast lines).
- **Strongest exhibits:** Table 2 (excellent logic) and Figure 6 (clear placebo evidence).
- **Weakest exhibits:** Figure 3 and 4 (too basic for the main argument) and the "naked" tables in Appendix C.
- **Missing exhibits:** 
    1. **A Map:** Since you use T-MSIS (state-level variation) and ZIP codes, a map showing the geographic distribution of hospitals or "Carve-in vs. Carve-out" states would be very "QJE-esque."
    2. **Coefficient Plot:** A plot showing the coefficients of the main effect when controlling for various sets of covariates (e.g., raw, with state FE, with hospital controls).

**Top 3 improvements:**
1.  **Professionalize Figure Aesthetics:** Remove all grey backgrounds and gridlines from all figures. Use a consistent, high-contrast color palette (e.g., black and navy instead of red and blue).
2.  **Create a "Main Results" Figure:** Combine the RDD plots for Medicaid (Figure 3) and Medicare (Figure 4) into a two-panel Figure 1 in the main text.
3.  **Clean up the Appendix:** Format the tables in Appendix C to match the quality of Table 2, including titles, notes, and proper alignment. Don't let the appendix look like a "data dump."