# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-09T18:07:47.760284
**Route:** Direct Google API + PDF
**Tokens:** 20997 in / 2877 out
**Response SHA256:** 35f9a345f626a4ec

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics by EPC Band"
**Page:** 9
- **Formatting:** High quality. Clean horizontal lines; no vertical gridlines. Consistent with AER/QJE "Booktabs" style.
- **Clarity:** Excellent. Columns are ordered logically by EPC band (G to A).
- **Storytelling:** Essential. It establishes the massive scale of the dataset (7M+ observations) and reveals that the sample is concentrated in the D/E/C range, justifying the focus on those boundaries.
- **Labeling:** Clear. Units (sq m, £, %) are explicitly stated in the row stubs.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Distribution of EPC Scores in Analysis Sample"
**Page:** 9
- **Formatting:** Professional. Good use of color for threshold lines.
- **Clarity:** High. The 10-point binning makes the overall distribution clear, and the colored dashed lines immediately identify the treatment thresholds.
- **Storytelling:** Strong. It visually supports the "Manipulation" argument by showing spikes at the thresholds (especially E/F).
- **Labeling:** Y-axis uses scientific notation (e.g., 3e+05). While common in R, top journals often prefer "0", "100,000", "200,000".
- **Recommendation:** **REVISE**
  - Change Y-axis labels from scientific notation to standard integers with commas (e.g., 300,000).
  - Ensure the color-coded text (E/F, D/E) matches the exact color of the dashed lines for better accessibility.

### Table 2: "RDD Estimates at EPC Band Boundaries"
**Page:** 13
- **Formatting:** Journal-ready. Panel structure is clear. Numbers are logically aligned.
- **Clarity:** Good. The inclusion of (39), (55), etc., under the boundary labels is helpful for readers familiar with the SAP score.
- **Storytelling:** This is the "Money Table." It concisely presents the main null result across the entire distribution.
- **Labeling:** Significance stars are well-defined. Standard errors are in parentheses.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "RDD Plots at EPC Band Boundaries"
**Page:** 14
- **Formatting:** Standard `rdrobust` output style.
- **Clarity:** Slightly cluttered because five plots are squeezed into one page. The Y-axes vary significantly across panels (12.3 to 12.9), which is necessary but requires careful reading.
- **Storytelling:** Crucial. It shows the "Well-Powered Null" visually. The B/C and A/B panels clearly show the instability/bunching discussed in the text.
- **Labeling:** The sub-headers (e.g., "E/F Boundary (score = 39)") are excellent.
- **Recommendation:** **REVISE**
  - The "Point size proportional to bin count" makes the A/B plot look very messy. Consider a fixed point size or a capped scale for point size to improve visual cleanliness in the right-hand panels.

### Figure 3: "Multi-Cutoff RDD Estimates"
**Page:** 15
- **Formatting:** Clean coefficient plot. 
- **Clarity:** Excellent. The vertical dashed line at 0.0 allows for an instant check of significance.
- **Storytelling:** Effectively summarizes Table 2. It highlights how the A/B estimate is the outlier.
- **Labeling:** Clear. Axis label "Log Price Discontinuity" is precise.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "EPC Label Effects by Period"
**Page:** 16
- **Formatting:** Standard.
- **Clarity:** Good. Row stubs for $N$ (effective) are helpful to see how the sample shrinks in the "Post-Crisis" period.
- **Storytelling:** Vital for the "Energy Crisis" argument. It proves the null holds even when energy prices tripled.
- **Labeling:** Period definitions (e.g., 18Q2–21Q3) are precise.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "EPC Label Effects Over Time"
**Page:** 16
- **Formatting:** Color-coded line plot.
- **Clarity:** A bit busy. The overlapping 95% CIs make it hard to distinguish the three lines.
- **Storytelling:** Redundant with Table 3 and Figure 5. 
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**
  - Figure 5 is a better version of this "over time" story. Figure 4 adds the D/E and C/D lines, but it becomes a "spaghetti" plot.

### Table 4: "Decomposition: Information vs Regulatory Effects at E/F Boundary"
**Page:** 17
- **Formatting:** Good use of Panel A and Panel B.
- **Clarity:** The calculation (E/F - C/D) is clearly explained in the notes.
- **Storytelling:** This addresses a core theoretical question. Even though the results are null, the framework is important for the "Information vs Regulation" argument.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Difference-in-Discontinuities Around MEES (April 2018)"
**Page:** 18
- **Formatting:** Very clean.
- **Clarity:** High. Focuses on the single most important policy break.
- **Storytelling:** Key robustness check.
- **Labeling:** Excellent.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Annual E/F and C/D Discontinuities, 2015–2023"
**Page:** 18
- **Formatting:** Excellent. Shaded region for energy crisis and vertical line for MEES are perfect.
- **Clarity:** Very high.
- **Storytelling:** This is the strongest "Dynamic" figure in the paper. It shows no trend or break at the policy dates.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS** (Wait—consider promoting to Figure 4's spot if Figure 4 is moved).

### Figure 6: "E/F Discontinuity by Tenure: Rental vs. Owner-Occupied"
**Page:** 19
- **Formatting:** Consistent with Figure 4.
- **Clarity:** Suffers from the same "overlapping CI" problem. The red and blue bars on the right (Post-Crisis) are so large they drown out the rest of the plot.
- **Storytelling:** Important to show that even in the rental market (where the law applies), there is no effect.
- **Labeling:** Good.
- **Recommendation:** **REVISE**
  - Cap the Y-axis or use a different visualization (like a small-multiples plot with two panels: Rental and Owner-Occupied) to avoid the massive CIs on the right from compressing the earlier, more precise data points.

### Table 6: "McCrary Density Tests at EPC Band Boundaries"
**Page:** 20
- **Formatting:** Standard.
- **Clarity:** $N_{left}$ and $N_{right}$ columns provide good context for the test statistics.
- **Storytelling:** Central to the "Manipulation" story.
- **Recommendation:** **KEEP AS-IS**

### Figure 7: "McCrary Density Tests"
**Page:** 21
- **Formatting:** Standard R output.
- **Clarity:** Excellent. Having all 5 thresholds on one page allows for easy comparison.
- **Storytelling:** Visually confirms the bunching at E/F and A/B.
- **Recommendation:** **KEEP AS-IS**

### Table 7: "E/F RDD Estimates: Full Sample vs Address-Matched Subsample"
**Page:** 22
- **Formatting:** Logical side-by-side comparison.
- **Clarity:** High.
- **Storytelling:** This is a "Validation" exhibit. It proves the results aren't driven by bad data matching.
- **Recommendation:** **MOVE TO APPENDIX**
  - This is a technical robustness check. It can be summarized in one sentence in the main text.

### Figure 8: "E/F Estimates: Full Sample vs Address-Matched Subsample"
**Page:** 22
- **Formatting:** Clean.
- **Clarity:** Good.
- **Storytelling:** Redundant if Table 7 is present.
- **Recommendation:** **REMOVE** (The text "virtually identical" is enough).

### Table 8: "Extended Donut RDD Estimates"
**Page:** 23
- **Formatting:** Uses "—" for suppressed columns, which is clean.
- **Clarity:** Good.
- **Storytelling:** Vital for showing that even when you "jump over" the manipulated scores, the null persists.
- **Recommendation:** **KEEP AS-IS**

### Figure 9: "Bandwidth Sensitivity"
**Page:** 24
- **Formatting:** Multi-panel plot.
- **Clarity:** High. The horizontal dashed line at 0 is the key.
- **Storytelling:** Standard but necessary for RDD papers.
- **Recommendation:** **KEEP AS-IS**

### Figure 10: "Real vs. Placebo Cutoffs"
**Page:** 25
- **Formatting:** Creative and clear.
- **Clarity:** Excellent. The contrast between red and grey points is immediate.
- **Storytelling:** Very strong "Placebo" test. It shows the E/F null is part of a larger pattern of no discontinuities anywhere.
- **Recommendation:** **KEEP AS-IS**

### Table 9: "Multiple Testing Correction"
**Page:** 25
- **Formatting:** Simple.
- **Clarity:** Clear.
- **Storytelling:** Final nail in the coffin for any "spurious significance" at A/B.
- **Recommendation:** **MOVE TO APPENDIX**
  - Can be stated in text: "After Holm-stepdown adjustment, no boundary is significant."

---

## Appendix Exhibits

### Table 10: "Covariate Balance Tests..."
**Page:** 35
- **Recommendation:** **KEEP AS-IS** (Standard appendix balance table).

### Table 11: "Decomposition Using D/E + C/D Average..."
**Page:** 36
- **Recommendation:** **KEEP AS-IS** (Technical robustness).

### Table 12: "E/F Boundary Estimates by Tenure and Period"
**Page:** 36
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - This table provides the numerical backing for Figure 6. Top journals prefer seeing the point estimates for tenure-specific effects in the main text when the policy (MEES) specifically targets one tenure (Rentals).

### Table 13: "Polynomial Order Sensitivity"
**Page:** 37
- **Recommendation:** **KEEP AS-IS**.

### Table 14: "Volume RDD at E/F Boundary"
**Page:** 38
- **Recommendation:** **KEEP AS-IS** (Supports the strategic selling/manipulation argument).

---

## Overall Assessment

- **Exhibit count:** 9 main tables, 10 main figures, 5 appendix tables, 0 appendix figures.
- **General quality:** Extremely high. The paper follows the "Standard Operating Procedure" for a modern RDD paper (balance, McCrary, donut, bandwidth sensitivity, placebos). It looks like an AEJ or AER paper.
- **Strongest exhibits:** Figure 5 (Annual Discontinuities) and Figure 10 (Placebo Cutoffs).
- **Weakest exhibits:** Figure 4 and Figure 6 (overlapping CI issues).
- **Missing exhibits:** 
    - **Summary Statistics for Covariates:** Table 1 focuses on EPC bands. A standard "Table 1" usually includes means/SDs for the whole sample for all variables used in regressions (floor area, age, etc.).
    - **A Map:** For a paper on "English Property Transactions," a heatmap showing the density of transactions or the average EPC rating by District would add great "flavor" and institutional context.

- **Top 3 improvements:**
  1. **Clean up Figure 4 and 6:** Use small-multiples (separate panels) instead of overlapping lines with large CIs to improve readability.
  2. **Consolidate Validation:** Move the Match Quality validation (Table 7/Figure 8) and Multiple Testing (Table 9) to the Appendix to tighten the main text.
  3. **Standardize Y-Axes:** Remove scientific notation in Figure 1 and ensure Figure 2's point sizes don't obscure the data trends in the low-N boundaries.