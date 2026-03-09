# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-09T12:57:16.846240
**Route:** Direct Google API + PDF
**Tokens:** 17357 in / 1856 out
**Response SHA256:** 1bdb921c8c7208c4

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Bilateral Trade at HS6 Level"
**Page:** 9
- **Formatting:** Generally professional but uses "Role" and "Product" as row headers in a way that creates a lot of vertical repetition. Decimal alignment is missing for the "Mean Trade" and "SD Trade" columns.
- **Clarity:** Clear, though the "N" column (observations) could be clarified to specify if it is $N$ country-product-year cells.
- **Storytelling:** Strong. It immediately shows the "jump" and "reversal" in the raw data, which sets up the regression results perfectly.
- **Labeling:** Good. Notes are comprehensive.
- **Recommendation:** **REVISE**
  - Use horizontal rules (booktabs style) more effectively: remove the vertical lines.
  - Decimal-align the dollar values.
  - Group the "Role" and "Product" headers to avoid repeating "Transit" and "CHPL" in every row; use a spanned header or sub-headings within the table.

### Table 2: "Main Results: Difference-in-Differences Estimates of CHPL Enforcement Effect"
**Page:** 12
- **Formatting:** Standard AER/QJE style. Uses "—" for excluded variables correctly.
- **Clarity:** Excellent. The transition from base to main specification is logical.
- **Storytelling:** This is the "money table." It validates the rerouting and the enforcement effect across different specifications.
- **Labeling:** Significance stars are standard. FE rows are clear. 
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Exports to Russia by Product Type, 2015–2024"
**Page:** 14
- **Formatting:** Clean ggplot2-style aesthetic. Gridlines are a bit heavy for top journals.
- **Clarity:** Extremely clear. The divergence in 2022 is the key message and it is visible in seconds.
- **Storytelling:** Vital. It provides the visual proof of the "Parallel Trends" assumption pre-2022.
- **Labeling:** Vertical lines for "Sanctions" and "CHPL" are helpful.
- **Recommendation:** **REVISE**
  - Remove the background gray grid or lighten it significantly to match AER/QJE house styles.
  - Increase the font size for the legend and axis titles.
  - Move the legend inside the plot area (top left) to save whitespace.

### Figure 2: "Transit Country CHPL Exports to Russia: Rerouting and Enforcement"
**Page:** 15
- **Formatting:** Identical to Figure 1.
- **Clarity:** This figure is essentially the red line from Figure 1. 
- **Storytelling:** **Redundant.** Figure 1 already contains this information and provides the necessary comparison to non-CHPL products.
- **Labeling:** Clear.
- **Recommendation:** **REMOVE** (Redundant with Figure 1).

### Table 3: "Heterogeneity by CHPL Tier: Enforcement Effects on Critical vs. Peripheral Components"
**Page:** 16
- **Formatting:** Professional.
- **Clarity:** Logical grouping.
- **Storytelling:** Advances the argument that "Tier 1-2" (most critical) saw the most enforcement, which is a key policy takeaway.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "CHPL Technology Rerouting by Transit Country, 2015–2024"
**Page:** 17
- **Formatting:** Stacked bar chart.
- **Clarity:** A bit busy. The decline in 2024 is visible, but the individual country trajectories are harder to track than in a line chart.
- **Storytelling:** Important for showing that the effect isn't driven by just one country (e.g., Kyrgyzstan).
- **Labeling:** Good.
- **Recommendation:** **REVISE**
  - Consider a faceted line chart (3 panels, one for each country) or a grouped line chart instead of a stacked bar. Stacked bars make it difficult to see the "pre-trend" for the countries at the top of the stack (Armenia).

### Table 4: "Rerouting Magnitude: Transit-Country Exports to Russia"
**Page:** 18
- **Formatting:** Simple, clear.
- **Clarity:** The "Peak/Pre" and "Decline" columns are highly effective for a policy audience.
- **Storytelling:** Excellent summary of the "economic significance" vs the "statistical significance."
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS** (Though consider merging into the bottom of Table 1 to save space).

### Figure 4: "Event Study: Differential CHPL Trade Through Transit Countries"
**Page:** 19
- **Formatting:** Professional event study plot with confidence intervals.
- **Clarity:** The 2024 drop is very clear.
- **Storytelling:** This is the most important figure for identification. It proves the "Parallel Trends" and the timing of the effect.
- **Labeling:** Excellent.
- **Recommendation:** **KEEP AS-IS** (Promote to Figure 2 now that the old Figure 2 is removed).

### Table 5: "Leave-One-Country-Out Estimates"
**Page:** 20
- **Formatting:** Professional.
- **Clarity:** Very clear.
- **Storytelling:** Robustness check that belongs in the main text given the small $N$ of countries (3).
- **Labeling:** Note explains the coefficients well.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Top CHPL Products: Rerouting Spike and Enforcement Collapse"
**Page:** 22
- **Formatting:** Spaghetti plot / Dot-and-line.
- **Clarity:** **Low.** This is a "hairball" chart. It is very difficult to distinguish which HS6 code is which.
- **Storytelling:** It shows the "whack-a-mole" nature described in the text, but doesn't identify the products clearly for the reader.
- **Labeling:** The legend is too long and uses codes that require looking up.
- **Recommendation:** **MOVE TO APPENDIX**
  - Or, replace with a horizontal bar chart showing the "Top 10" products and their percentage decline in 2024.

---

## Appendix Exhibits

### Table 6: "Standardized Effect Sizes for Main Outcomes"
**Page:** 31
- **Formatting:** Clear.
- **Clarity:** Good for cross-study comparison.
- **Storytelling:** A bit meta-analytical; appropriate for an appendix.
- **Labeling:** Very thorough notes.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 5 main tables, 5 main figures, 1 appendix table, 0 appendix figures.
- **General quality:** The tables are very high quality and journal-ready. The figures are informative but the styling is a bit "default" (ggplot2) and could be refined for the AER/QJE aesthetic.
- **Strongest exhibits:** Table 2 (Main Results) and Figure 4 (Event Study).
- **Weakest exhibits:** Figure 2 (Redundant) and Figure 5 (Too cluttered).
- **Missing exhibits:** 
  1. **Map Figure:** A map of the three transit countries (Armenia, Kazakhstan, Kyrgyzstan) relative to Russia would be very helpful for readers unfamiliar with the geography of Central Asian trade.
  2. **Product List Table:** A table in the appendix listing all 24 CHPL codes and 18 non-CHPL codes used in the study.

### Top 3 Improvements:
1.  **Streamline Figures:** Remove Figure 2 (redundant) and move Figure 5 to the Appendix. This tightens the narrative.
2.  **Refine Visual Style:** Remove background grids from Figures 1, 3, and 4. Use a white background with black axes to match the high-end academic look.
3.  **Consolidate Descriptive Evidence:** Merge Table 4 into Table 1. This puts the raw means and the calculated magnitudes in one place, providing a "one-stop shop" for the descriptive story.