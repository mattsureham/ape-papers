# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-09T18:16:47.355972
**Route:** Direct Google API + PDF
**Tokens:** 21517 in / 1862 out
**Response SHA256:** f78dde90615c84b8

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics"
**Page:** 13
- **Formatting:** Generally professional. Uses standard booktabs-style horizontal lines. Decimal points are mostly aligned, though "Mean" for Total Votes is quite large and creates a wide column.
- **Clarity:** Very clean. Logical grouping of outcome variables, treatment variables, and panel dimensions.
- **Storytelling:** Essential. It establishes the scale of the RN vote share and the variation in the shift-share instrument.
- **Labeling:** Good. Includes units (%) where appropriate. Notes are comprehensive.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Effect of Network Asylum Exposure on RN Vote Share"
**Page:** 16
- **Formatting:** Journal-ready. Proper use of parentheses for standard errors. The "Within R²" row is a nice addition for FE models.
- **Clarity:** The column headers (1)-(5) are clear. However, variable names like `NetDisp x Post x NonHost` are slightly "coded."
- **Storytelling:** This is the "money table" of the paper. It logically moves from baseline to controls, to standardized effects, to the triple-difference. 
- **Labeling:** Clear. Significance stars are defined. Note explains the standardization in (3)-(4).
- **Recommendation:** **REVISE**
  - Change variable labels for publication: replace `NetDisp x Post x NonHost` with "Network Dispersal $\times$ Post $\times$ Non-Hosting" to avoid looking like raw Stata/R output.
  - Ensure the dependent variable "RN Vote Share (%)" is centered across all five columns.

### Figure 1: "Event Study: Network Dispersal and RN Vote Share"
**Page:** 18
- **Formatting:** Professional. Use of a dashed line for the reference period and a dotted red line for the treatment timing is standard.
- **Clarity:** High. The 10-second takeaway (parallel trends, then a break) is immediate. 
- **Storytelling:** Crucial for validating the DiD design. It addresses the 2014 outlier transparently.
- **Labeling:** The y-axis label uses a Greek $\hat{\beta}_t$ which is standard, but "times Election" is a bit clunky.
- **Recommendation:** **REVISE**
  - Simplify y-axis label to "Coefficient on Network Dispersal."
  - The "SNA 2021" text is slightly small; increasing font size for the intervention label would improve readability on printed pages.

### Figure 2: "Leave-One-Out Coefficients"
**Page:** 19
- **Formatting:** Clean. The x-axis (Department codes) is very crowded but necessarily so for 96 units.
- **Clarity:** The red dashed line for the baseline estimate makes the "stability" message clear.
- **Storytelling:** Good for robustness, though arguably could live in an appendix. Given the importance of shift-share sensitivity, keeping it here is acceptable for a top journal.
- **Labeling:** Adequate.
- **Recommendation:** **KEEP AS-IS** (or move to appendix if space is tight).

### Figure 3: "Randomization Inference Distribution"
**Page:** 20
- **Formatting:** High quality. Clear contrast between the null distribution and the observed statistic.
- **Clarity:** Excellent. The p-value is visually obvious.
- **Storytelling:** Strong support for the validity of the shift-share instrument. 
- **Labeling:** "RI p-value = 0" should technically be "$p < 0.001$" as 0 is not statistically possible in 1,000 permutations.
- **Recommendation:** **REVISE**
  - Change "RI p-value = 0" to "$p < 0.001$".

### Table 3: "Inference Methods for Shift-Share Design"
**Page:** 21
- **Formatting:** Standard. 
- **Clarity:** Clear, but the information is almost entirely contained in Table 2 or the text.
- **Storytelling:** A bit redundant. Most top journals prefer these types of alternate SEs to be reported in a single robustness table or a footnote.
- **Recommendation:** **REMOVE**
  - Incorporate the HC1 or Wild Bootstrap p-values into Table 4 instead.

### Table 4: "Robustness Checks"
**Page:** 22
- **Formatting:** Good. Logical structure.
- **Clarity:** "Non-RN share (mechanical)" is a bit confusing at first glance.
- **Storytelling:** Excellent summary of the paper's resilience.
- **Labeling:** Comprehensive notes.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Network Dispersal Effect by Department Characteristics"
**Page:** 24
- **Formatting:** Clean lines, good use of colors/shading for 95% CIs.
- **Clarity:** Very high. The diverging trends after 2021 for different exposure levels are clear.
- **Storytelling:** Supports the mechanism section. 
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Figure 5: "Coefficient Comparison Across Specifications"
**Page:** 35
- **Formatting:** Standard "whisker" plot.
- **Clarity:** Good for comparing magnitudes.
- **Storytelling:** Slightly redundant with Table 4, but useful for a visual summary of stability.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Geographic Distribution of Network Dispersal"
**Page:** 36
- **Formatting:** Map is well-rendered.
- **Clarity:** The color scale (red) is appropriate.
- **Storytelling:** Very helpful. Readers of French political economy expect to see the "hexagon." It helps visualize which departments are "connected" to the shifts.
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - This should be Figure 1 or 2 in the main text. Understanding the spatial variation of the treatment is fundamental to the paper’s "Halo Effect" argument.

### Table 5: "Pre-Treatment Balance: Covariates by Network Dispersal Tercile"
**Page:** 38
- **Formatting:** Standard balance table.
- **Clarity:** High.
- **Storytelling:** Essential for the identification argument.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Standardized Effect Sizes for Main Outcomes"
**Page:** 39
- **Formatting:** A bit cluttered with the "Research Question/Treatment/Data" text blocks at the bottom.
- **Clarity:** The table itself is clear, but the extensive text below it belongs in the Appendix text, not the table notes.
- **Storytelling:** Helpful for interpretation.
- **Recommendation:** **REVISE**
  - Move the long descriptive text (Research question, Treatment, etc.) into the Appendix text. Keep only the table and a brief note about SDE calculation.

---

## Overall Assessment

- **Exhibit count:** 4 main tables, 4 main figures, 2 appendix tables, 2 appendix figures.
- **General quality:** Extremely high. The exhibits use a consistent aesthetic (likely `ggplot2` in R or `grstyle` in Stata) that feels modern and professional.
- **Strongest exhibits:** Figure 1 (Event Study) and Table 2 (Main Results).
- **Weakest exhibits:** Table 3 (Redundant) and the y-axis labeling in some figures.
- **Missing exhibits:** A map of the "Shifts" (the actual new asylum places by department) would be a great companion to the "Share" or "Network Exposure" map to show where the policy change actually happened.

### Top 3 Improvements:
1.  **Promote the Map (Figure 6) to the main text.** Spatial papers need to ground the reader in geography early.
2.  **Clean up variable labels in Table 2.** Remove underscores and "coded" abbreviations (e.g., use "Network Dispersal" instead of `NetDisp`).
3.  **Consolidate Inference.** Remove Table 3 and ensure the p-values for alternative inference methods are simply noted in the text or added as a row in Table 4 to reduce exhibit clutter.