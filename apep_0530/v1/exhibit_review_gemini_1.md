# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-05T22:37:44.677508
**Route:** Direct Google API + PDF
**Tokens:** 14757 in / 1899 out
**Response SHA256:** 6802edea48b49bf1

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics by Designation Group and Location (500m Bandwidth)"
**Page:** 10
- **Formatting:** Generally clean. However, numbers in columns (Mean Price/sqm, SD Price/sqm) should be right-aligned or decimal-aligned to improve readability. 
- **Clarity:** Excellent. The 500m restriction is clear, and the groups are logical.
- **Storytelling:** This is essential for the "Simpson’s Paradox" argument mentioned in the text. It justifies the inclusion of controls.
- **Labeling:** Good. Clear units (sqm). Note: Ensure "% Apartment" is clearly defined (is it a 0–100 scale or 0–1?).
- **Recommendation:** **KEEP AS-IS** (with minor alignment tweaks).

### Table 2: "Main Regression Results"
**Page:** 13
- **Formatting:** Professional. Standard errors in parentheses, significance stars used correctly. 
- **Clarity:** Logic of building from pooled to controlled specifications is easy to follow.
- **Storytelling:** This is the "money table." It clearly shows that while raw effects are similar, controlling for housing characteristics (Column 3) increases the magnitude of the "Gained" penalty.
- **Labeling:** "Inside Zone" and "Inside $\times$ Gained" labels are clear. Notes explain the clustering and sample restrictions.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "RDD Estimates at Zone Boundaries"
**Page:** 14
- **Formatting:** A bit sparse. The wide spacing between columns makes it slightly harder to read than Table 2.
- **Clarity:** High. Shows the crucial asymmetry found at very narrow bandwidths.
- **Storytelling:** Excellent. It provides the "nuance" that the parametric results miss.
- **Labeling:** SEs are not in parentheses here, whereas they are in Table 2. **Consistency is key for top journals.** 
- **Recommendation:** **REVISE**
  - Put SEs in parentheses.
  - Add a note defining "Optimal BW" (MSE-optimal).
  - Add significance stars to the "Estimate" column instead of a separate column or trailing the N.

### Figure 1: "Boundary Price Discontinuity by Year"
**Page:** 15
- **Formatting:** The light blue/grey aesthetic is clean, but the y-axis gridlines are a bit faint.
- **Clarity:** The overlap of confidence intervals in 2022/2023 for "Gained" makes it look slightly cluttered. 
- **Storytelling:** Important for establishing that these are equilibrium effects, not a temporary shock.
- **Labeling:** Y-axis label "Log price per sqm (inside - outside)" is technically correct but wordy. "$\Delta$ Log Price" might be cleaner.
- **Recommendation:** **REVISE**
  - Slightly offset the x-axis positions for the two groups (jittering) so the 95% CI bars do not overlap directly on top of each other.

### Figure 2: "Sensitivity of Estimates to Bandwidth Choice"
**Page:** 16
- **Formatting:** Good use of point shapes (circles vs squares) to distinguish groups.
- **Clarity:** Very clear. The stability of the coefficients is the main takeaway.
- **Storytelling:** Crucial for RDD/Boundary designs. 
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Donut RDD Estimates"
**Page:** 16
- **Formatting:** The "Donut (m)" column has repeating values. This could be cleaner.
- **Clarity:** It's a bit repetitive.
- **Storytelling:** This could potentially be a figure (similar to Figure 2) to show the "instability" of the Gained estimate at larger donuts more visually.
- **Labeling:** SEs are not in parentheses.
- **Recommendation:** **REVISE**
  - Put SEs in parentheses. 
  - Group rows by "Donut (m)" using a sub-header or whitespace to avoid repeating the number in every row.

### Table 5: "Covariate Balance at Zone Boundaries (500m bandwidth)"
**Page:** 17
- **Formatting:** Professional.
- **Clarity:** The "Pct Diff" column is a great addition for interpreting the magnitude of imbalance.
- **Storytelling:** Essential for transparency. It admits the design doesn't have "perfect" balance but shows the imbalance is consistent across types.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Transaction Density at QPV Zone Boundaries"
**Page:** 18
- **Formatting:** Standard McCrary-style density plots. 
- **Clarity:** Using two panels (Gained vs Retained) is the correct choice.
- **Storytelling:** Validates the "no-sorting" assumption.
- **Labeling:** X-axis needs a clearer label (e.g., "Distance to Boundary (m)"). 
- **Recommendation:** **REVISE**
  - Add a vertical dashed line at 0 for both panels to emphasize the boundary.

### Figure 4: "Property Prices at QPV Zone Boundaries"
**Page:** 19
- **Formatting:** Very high quality. The loess fit with shaded CIs is QJE/AER standard.
- **Clarity:** The "jump" at zero is visually undeniable.
- **Storytelling:** The most important visual proof of the paper's identification strategy.
- **Labeling:** Excellent.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Designation Effects by Property Type (Mechanism Test)"
**Page:** 19
- **Formatting:** Consistent with Table 3 (needs parentheses for SEs).
- **Clarity:** Clear grouping.
- **Storytelling:** Vital for the "stigma vs. social housing" argument.
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - Put SEs in parentheses.
  - This table and Figure 5 are somewhat redundant. Pick one for the main text and move the other to the appendix. Table 6 provides more precision.

### Figure 5: "Boundary Discontinuity by Property Type"
**Page:** 20
- **Formatting:** Clean coefficient plot.
- **Clarity:** High.
- **Storytelling:** Redundant with Table 6. 
- **Recommendation:** **MOVE TO APPENDIX** (Table 6 is more informative for a results section).

---

## Appendix Exhibits

### Table A1: "Bandwidth Sensitivity: Full Results"
**Page:** 26
- **Formatting:** Good. Standard errors are in parentheses here (unlike Table 3/4).
- **Clarity:** High.
- **Storytelling:** Good supporting data for Figure 2.
- **Labeling:** Professional.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 6 main tables, 5 main figures, 1 appendix table, 0 appendix figures.
- **General quality:** Extremely high. The figures (especially Figure 4) are journal-ready and follow the "Tufte" style of high data-to-ink ratio favored by top economics journals.
- **Strongest exhibits:** Table 2 (Main Results) and Figure 4 (RDD Scatter).
- **Weakest exhibits:** Table 3 and Table 4 (Formatting of SEs).
- **Missing exhibits:** 
    - **A Map:** A paper on French urban boundaries *needs* a map. Even if it's just a "zoom-in" of one QPV zone in a city like Paris or Nantes showing the 200m grid-based boundary vs. the urban fabric. This would ground the paper's spatial logic.
    - **Outcome Variable in Levels:** A table or figure showing the raw price levels (not logs) could help readers understand the real-world Euro impact.

- **Top 3 improvements:**
  1. **Standardize Table Formatting:** Ensure all tables (specifically 3, 4, and 6) use parentheses for standard errors and consistent decimal alignment.
  2. **Add a Visual Map:** Include a figure showing a representative QPV boundary and the location of transactions to illustrate the identification strategy.
  3. **De-clutter Figure 1:** Jitter the year-by-year estimates so the confidence intervals are easier to distinguish.