# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-10T14:31:55.733584
**Route:** Direct Google API + PDF
**Tokens:** 19957 in / 1919 out
**Response SHA256:** 14e4b48284c6f315

---

This review evaluates the visual exhibits of "Bail-In Risk and the Maturity Structure of Household Deposits" for submission to top-tier economics journals.

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics"
**Page:** 10
- **Formatting:** Generally professional. Uses standard booktabs style.
- **Clarity:** Excellent. Separating outcomes (Panel A) from treatment variables (Panel B) is logical.
- **Storytelling:** Essential for establishing the baseline composition of European deposits.
- **Labeling:** Clear. Total deposits in EUR M are a bit hard to read with many digits; $Log$ is provided which helps.
- **Recommendation:** **REVISE**
  - Change "Total deposits (EUR M)" to "Total deposits (EUR Billion)" and divide by 1,000 to make the numbers easier to parse (e.g., 339.79 instead of 339791.65).
  - Use a comma as a thousands separator for the Max value in Panel A.

### Table 2: "BRRD Transposition and Household Deposit Composition"
**Page:** 14
- **Formatting:** Good use of panels and clear column headers.
- **Clarity:** Strong. The comparison between the biased TWFE and the Intensity Interaction is the core "hook."
- **Storytelling:** High impact. It shows the failure of standard DiD and the success of the intensity design.
- **Labeling:** Stars are defined. Units (0–1 scale) are clear in notes but should be in the table.
- **Recommendation:** **REVISE**
  - Add "(Share 0-1)" under the column titles (1)-(5) so the reader doesn't have to hunt in the notes for the unit of measurement.
  - The coefficient -0.0054 in Col 1 is discussed as -0.54 pp in text; consider multiplying all coefficients by 100 to show "Percentage Points" directly.

### Table 3: "Heterogeneity-Robust Estimators: Callaway-Sant’Anna and Sun-Abraham"
**Page:** 15
- **Formatting:** Clean and consistent with Table 2.
- **Clarity:** High. Provides the necessary "methodological correctness" check required by top journals today.
- **Storytelling:** Crucial. It "fixes" the sign reversal in Table 2.
- **Labeling:** SE types are clearly identified (Clustered vs. Analytic).
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Event Study: Household Overnight Deposit Share"
**Page:** 16
- **Formatting:** Modern and clean. Blue color is professional.
- **Clarity:** The key message (no pre-trend, gradual post-rise) is visible in 5 seconds.
- **Storytelling:** This is the most important figure in the paper for identification.
- **Labeling:** Y-axis clearly labeled "ATT (pp)".
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Event Study: Household Agreed-Maturity Deposit Share"
**Page:** 17
- **Formatting:** Identical to Figure 1 but in red.
- **Clarity:** Clean.
- **Storytelling:** Supports the "no average effect" for term deposits.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX** — The paper's "story" is about the overnight shift and the intensity heterogeneity. This null result takes up a lot of main-text real estate.

### Figure 3: "Treatment Intensity: Change in Overnight Share vs. Cross-Sectional Uninsured Exposure"
**Page:** 18
- **Formatting:** Good use of country labels (ISO codes).
- **Clarity:** A bit cluttered with labels. The "main message" header is helpful but slightly "journalistic."
- **Storytelling:** Visualizes the $Post \times Uninsured$ interaction from Table 2.
- **Labeling:** Clear axes.
- **Recommendation:** **REVISE**
  - Remove the blue text header *inside* the plot area ("High-exposure countries shifted..."); move this information to the Figure Title or a Note to maintain AER/QJE formality.
  - Slightly increase the transparency of the confidence interval band.

### Table 4: "Placebo Test: Corporate Deposits and Sector Difference-in-Differences"
**Page:** 19
- **Formatting:** Standard.
- **Clarity:** Clear.
- **Storytelling:** Vital placebo check.
- **Labeling:** Notes are comprehensive.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Household vs. Corporate Overnight Deposit Share"
**Page:** 20
- **Formatting:** Very clean line plot.
- **Clarity:** Extremely high.
- **Storytelling:** Shows the parallel evolution and lack of a corporate break.
- **Labeling:** Legend is clear.
- **Recommendation:** **REVISE**
  - Change the X-axis from "2012, 2014..." to include the vertical line more prominently.
  - The "Corporations (placebo) show no structural break" header should be removed from the plot area (keep it formal).

### Figure 5: "Deposit Composition by Transposition Timing Group"
**Page:** 21
- **Formatting:** Multi-panel (a and b).
- **Clarity:** Good.
- **Storytelling:** Illustrates the staggered design.
- **Labeling:** X-axis is a bit sparse.
- **Recommendation:** **KEEP AS-IS** (Though redundant with Figure 1/2, it is a good "raw data" visualization).

---

## Appendix Exhibits

### Table 5: "BRRD National Transposition Dates and Deposit Insurance Coverage"
**Page:** 31
- **Formatting:** Excellent data table.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Leave-One-Out Sensitivity of TWFE Overnight Share Estimate"
**Page:** 23 (Printed in main text, but part of Appendix section C)
- **Formatting:** Standard "caterpillar" plot.
- **Recommendation:** **KEEP AS-IS** (Ensure it is physically located in the Appendix in the final submission).

### Figure 7: "BRRD National Transposition Timeline"
**Page:** 33
- **Clarity:** High. Excellent for explaining the "Staggered" nature to a reviewer.
- **Recommendation:** **KEEP AS-IS**

### Figure 8: "Randomization Inference: Distribution of Permuted TWFE Estimates"
**Page:** 34
- **Formatting:** Standard histogram.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Summary of Robustness Checks"
**Page:** 35
- **Storytelling:** This is very helpful for reviewers. It consolidates many tests.
- **Recommendation:** **KEEP AS-IS**

### Table 7: "Standardized Effect Sizes for Main Outcomes"
**Page:** 36
- **Formatting:** A bit unusual for econ, looks like a clinical trial report.
- **Recommendation:** **REVISE**
  - Remove the "Classification" column (e.g., "Small negative"). Economists prefer to judge the magnitude themselves based on the context provided in the text.

---

## Overall Assessment

- **Exhibit count:** 5 Main Tables, 5 Main Figures, 2 Appendix Tables, 3 Appendix Figures.
- **General quality:** High. The paper follows the modern "Staggered DiD" template perfectly.
- **Strongest exhibits:** Figure 1 (Event Study) and Table 2 (Main Results).
- **Weakest exhibits:** Figure 2 (Null result takes too much space) and Figure 3 (Cluttered labels).
- **Missing exhibits:** 
  - **A Figure for the "Insurance Optimization" result:** The paper claims high-exposure households move *into* term deposits. While Table 2 shows this, a binscatter or a split event study for "High vs. Low Uninsured Share" countries would be more convincing than Figure 3.
- **Top 3 improvements:**
  1. **Clean Figure Plot Areas:** Remove the "Main Message" text headers from inside the graphs (Figures 1, 3, 4, 8). These belong in the caption or the body text.
  2. **Coordinate Units:** Decide between 0-1 shares or Percentage Points. I recommend multiplying all coefficients and summary stats by 100 to use "Percentage Points" throughout.
  3. **Streamline Main Text:** Move Figure 2 to the Appendix to keep the reader focused on the primary overnight deposit finding.