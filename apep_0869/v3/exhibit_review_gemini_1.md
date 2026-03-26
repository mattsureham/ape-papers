# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-26T15:41:40.084074
**Route:** Direct Google API + PDF
**Tokens:** 15797 in / 1687 out
**Response SHA256:** 38e65c25ed17cb9f

---

This review evaluates the visual exhibits of the paper "Enforcement Design and Industry Adjustment: Evidence from Biometric Litigation Risk" for submission to a top-tier economics journal (AER, QJE, JPE, ReStud, Econometrica, AEJ: Policy).

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Conceptual Framework: Predictions and Tests"
**Page:** 7
- **Formatting:** Clean, uses standard booktabs-style horizontal lines.
- **Clarity:** Excellent. It provides a roadmap for the empirical section.
- **Storytelling:** Strong. It connects the abstract theory in Section 4 to the specific regressions that follow.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "The Litigation Tax: Continuous-Exposure Triple-Difference"
**Page:** 13
- **Formatting:** Professional. Good use of grouping for "Border Counties" vs "All Counties." Standard errors are correctly in parentheses.
- **Clarity:** High. Column headers clearly indicate the dependent variable.
- **Storytelling:** This is the "money" table of the paper. It highlights the contrast between the border (strong effect) and the state-wide sample (attenuated effect).
- **Labeling:** Significance stars are defined. Note explains the triple-interaction term clearly.
- **Recommendation:** **REVISE**
  - **Improvement:** Decimal-align the coefficients and standard errors. Currently, they appear centered, which makes comparing magnitudes across columns slightly harder for the eye.

### Table 3: "Employment Effects Track Biometric Exposure"
**Page:** 14
- **Formatting:** Journal-ready.
- **Clarity:** Very high. Logical ordering by exposure intensity.
- **Storytelling:** Essential for the "continuous treatment" argument. It proves the effect isn't driven by a single outlier industry.
- **Labeling:** Good.
- **Recommendation:** **REVISE**
  - **Improvement:** This table and Figure 1 (on the same page) are redundant. In a top journal, you should either merge these into a single multi-panel exhibit or move the table to the appendix and keep the figure, as the figure visualizes the "gradient" more effectively.

### Figure 1: "Employment Effects Track Biometric Exposure"
**Page:** 14
- **Formatting:** Good use of a scatter plot with a fitted trend line.
- **Clarity:** A bit cluttered. The labels for "admin_services" and "finance" overlap or are very close to other points. 
- **Storytelling:** Directly visualizes the core identifying variation.
- **Labeling:** Clear axes.
- **Recommendation:** **REVISE**
  - **Improvement:** Use `ggrepel` or manual placement to ensure industry labels do not overlap with error bars or each other (e.g., "admin_services" in the top right).
  - **Improvement:** The y-axis label "log points" is correct but "Percent Change" is often more intuitive for readers.

### Figure 2: "Event Study: Employment Effect of Biometric Litigation Exposure"
**Page:** 15
- **Formatting:** Standard event study format. Confidence intervals are clear.
- **Clarity:** The "Rosenbach (2019Q1)" vertical line is essential and well-placed.
- **Storytelling:** Shows the timing of the break.
- **Labeling:** The note about 95% CIs is good.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Employment and Establishment Dynamics in High-Exposure Industries"
**Page:** 15
- **Formatting:** Multi-line plot. 
- **Clarity:** Distinguishing between the blue and orange shaded regions is easy.
- **Storytelling:** Crucial for the "Scale Compression" (Margin 2) argument.
- **Labeling:** Legend is clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Randomization Inference: Actual vs. Placebo Estimates"
**Page:** 16
- **Formatting:** Histogram with a "true" value line.
- **Clarity:** Clear.
- **Storytelling:** Necessary given the small number of clusters (6 states).
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**
  - **Reasoning:** While important for rigor, the result (p=0.167) is mentioned in the text and Table 4. In a main text with many figures, this is a secondary "robustness" check.

### Table 4: "Robustness: Employment Effects Under Alternative Specifications"
**Page:** 17
- **Formatting:** Standard robustness table.
- **Clarity:** Compares many specifications efficiently.
- **Storytelling:** Validates the main result against COVID, pre-trends, and inference concerns.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Summary Statistics: Border Counties, 2015–2024"
**Page:** 18
- **Formatting:** Panel structure (A and B) is helpful.
- **Clarity:** Numbers are easy to read.
- **Storytelling:** Provides the scale of the sectors.
- **Labeling:** Note explains the data source.
- **Recommendation:** **REVISE**
  - **Improvement:** Move the "Exposure" column in Panel B to be the first column after the sector name. It is the treatment variable and should be prominent.

---

## Appendix Exhibits

### Table 6: "Standardized Effect Sizes"
**Page:** 28
- **Formatting:** Very dense notes section.
- **Clarity:** The "Classification" column (Moderate/Small) is a bit unusual for top econ journals—usually, authors let the reader judge the magnitude.
- **Storytelling:** Helpful for comparing BIPA to other legal shocks like wrongful discharge.
- **Labeling:** Definitions in notes are very thorough.
- **Recommendation:** **KEEP AS-IS** (as an appendix item).

---

## Overall Assessment

- **Exhibit count:** 5 main tables, 4 main figures, 1 appendix table.
- **General quality:** High. The exhibits follow the "Minimalist" style preferred by the AER/QJE (no gridlines, clear fonts, strong focus on the primary coefficient).
- **Strongest exhibits:** Table 2 (Main Results) and Figure 3 (Divergence plot).
- **Weakest exhibits:** Figure 1 (Label crowding) and Figure 4 (Visual simplicity suggests it belongs in an appendix).
- **Missing exhibits:** 
  1. **A Map:** A paper relying on "Border Counties" vs "Interior Counties" almost always needs a map figure showing the treated Illinois counties and the control neighboring counties. This helps a reader immediately grasp the geography.
  2. **Raw Data Plot:** A simple plot of *total* employment in high-exposure vs low-exposure industries (raw levels, not just coefficients) helps build trust in the underlying data before the regression results.

### Top 3 Improvements:

1.  **Add a Geography Map:** Create a Figure 1 that maps the Illinois border counties and their neighbors. Use colors to shade the "Biometric Exposure" by county or sector if possible.
2.  **Consolidate Table 3 and Figure 1:** These show the same data. Keep the Figure in the main text (it’s more "AER-style") and move the Table to the appendix.
3.  **Decimal Alignment:** Ensure all tables (especially Table 2 and Table 5) use decimal alignment for columns of numbers to improve readability and professionalism.