# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-04-07T20:40:28.076403
**Route:** Direct Google API + PDF
**Tokens:** 16837 in / 1926 out
**Response SHA256:** 4205cad447c8b9ae

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Establishments in 80–120 Employee Bandwidth"
**Page:** 9
- **Formatting:** Clean, but missing horizontal rules (Booktabs style) between the header and the first row. The decimal alignment for TCR and DART is inconsistent (e.g., 17.86 has two decimals, 8.77 has two, but others lack trailing zeros).
- **Clarity:** Good. The stratification into four groups clearly shows the variation used for identification.
- **Storytelling:** Strong. It immediately highlights the "outlier" problem mentioned in the text (SD of TCR is much higher in the non-App B group).
- **Labeling:** Clear. Abbreviations (TCR, DART) are well-defined in the notes.
- **Recommendation:** **REVISE**
  - Use `booktabs` for horizontal lines.
  - Decimal-align all numeric columns.
  - Add a column for the number of unique establishments if possible, or clarify if N is establishment-years.

### Figure 1: "Employee Count Distribution Around the 100-Employee Threshold"
**Page:** 13
- **Formatting:** Excellent. Professional use of overlays and panels.
- **Clarity:** Very high. The 10-second rule is met: one can clearly see the "post" orange bars exceeding the "pre" blue bars just before the 100-mark in the top panel.
- **Storytelling:** This is the "money plot" of the paper. It perfectly visualizes the triple-difference logic of the McCrary tests.
- **Labeling:** Axis labels are clear. Legend is well-placed.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Injury Rates at the 100-Employee Reporting Threshold"
**Page:** 14
- **Formatting:** The shaded confidence intervals are a bit "heavy."
- **Clarity:** The "Reporting threshold" label overlaps slightly with the dashed line; it should be offset more clearly.
- **Storytelling:** Essential for showing the null result. However, it only shows 2024.
- **Labeling:** Good. "Total Case Rate (per 100 FTE)" is a proper y-axis label.
- **Recommendation:** **REVISE**
  - Move the "Reporting threshold" text to the side. 
  - Consider making the point size legend visible (it mentions point size is proportional to bin count but doesn't show a scale).

### Table 2: "Main Results: Injury Rates at the 100-Employee Reporting Threshold"
**Page:** 16
- **Formatting:** Journal-ready. Standard errors in parentheses. Significance stars used correctly.
- **Clarity:** Column headers (1)-(5) are clear. Row labels for interactions are explicit.
- **Storytelling:** The table effectively moves from simple RDD (1-3) to the main DinD (4-5).
- **Labeling:** "above100" and "emp_centered" are slightly "codish."
- **Recommendation:** **REVISE**
  - Rename variables to "1(Employees $\ge$ 100)", "Rel. Employment", "Appendix B", etc., for a cleaner look.
  - Fix the $R^2$ formatting for column (1) ($3.52 \times 10^{-5}$ is scientifically accurate but rarely seen in econ journals; "0.000" or "$<$0.001" is more standard).

### Figure 3: "Difference-in-Discontinuities: Treated vs. Control Industries"
**Page:** 17
- **Formatting:** Clear colors.
- **Clarity:** The blue outlier in the far left (low employee count) for the control group is distracting.
- **Storytelling:** This is a visual version of the DinD. It’s a bit cluttered compared to Figure 2.
- **Labeling:** Good.
- **Recommendation:** **MOVE TO APPENDIX** 
  - This figure is redundant if Figure 2 and Table 2 are in the main text. The outlier makes the slopes look strange.

### Table 3: "Year-by-Year RDD Estimates at 100 Employees"
**Page:** 17
- **Formatting:** Professional.
- **Clarity:** Good. Shows the 2022 anomaly clearly.
- **Storytelling:** Crucial for the "parallel trends" argument of the RDD.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Event Study: Year-by-Year RDD Estimates at 100 Employees"
**Page:** 18
- **Formatting:** Standard event study plot.
- **Clarity:** The y-axis scale is dominated by the 2016 CI, making the 2017-2024 results look like a flat line.
- **Storytelling:** Visually proves the pre-trend (except for 2016/2022).
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - Consider a version that "zooms in" on 2017-2024 or uses a broken y-axis, as the 2016 variance is so high it hides the variation in later years.

### Table 4: "Robustness: Bandwidth Sensitivity"
**Page:** 20
- **Formatting:** Standard.
- **Clarity:** Very easy to read.
- **Storytelling:** Standard robustness check.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**
  - Figure 5 (which visualizes this) is more effective for the main text.

### Figure 5: "Bandwidth Sensitivity of RDD Estimates"
**Page:** 21
- **Formatting:** Clean.
- **Clarity:** High.
- **Storytelling:** Confirms the result isn't sensitive to the 20-employee window.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Placebo Cutoff Tests"
**Page:** 22
- **Formatting:** Good use of color to distinguish the actual threshold.
- **Clarity:** High.
- **Storytelling:** Strong evidence that 100 is the only meaningful threshold.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Table 5: "Standardized Effect Sizes"
**Page:** 30
- **Formatting:** The notes are extremely dense (block text).
- **Clarity:** The "Classification" column is unusual for an economics paper (more common in medical journals). 
- **Storytelling:** Helps interpret the "null" result, which is a major part of the paper's argument.
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - Break the notes into paragraphs or bullet points. Remove the "Classification" column; economists generally prefer to judge magnitude based on the SDE/coefficient directly rather than a "Small/Null" label.

---

## Overall Assessment

- **Exhibit count:** 4 main tables, 6 main figures, 1 appendix table, 0 appendix figures.
- **General quality:** High. The figures are modern and emphasize the "Difference-in-Discontinuities" design well.
- **Strongest exhibits:** Figure 1 (Density/Bunching) and Figure 6 (Placebos).
- **Weakest exhibits:** Figure 3 (cluttered by outliers) and Table 5 (overly descriptive notes).
- **Missing exhibits:** 
  1. **Industry Breakdown Table:** A table showing the bunching estimate ($T$-stat) by broad industry (Manufacturing vs. Services) would be very impactful given the text's discussion on heterogeneity.
  2. **Data Example Figure:** A screenshot or mock-up of what the "Publicly Searchable Database" looks like (the "Sunlight") would help the reader understand the "cost" firms are avoiding.

**Top 3 improvements:**
1. **Consolidate Robustness:** Move Table 4 to the appendix and rely on Figure 5 in the main text. Move Figure 3 to the appendix.
2. **Clean up Table 2:** Replace regression variable names (above100) with descriptive LaTeX/formatted labels.
3. **Address Outliers in Plots:** For Figure 3 and Figure 4, winsorize the data or adjust the y-axis to prevent 2016/outliers from compressing the visual information of the primary treatment years.