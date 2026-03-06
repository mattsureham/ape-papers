# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-06T19:10:42.764541
**Route:** Direct Google API + PDF
**Tokens:** 20997 in / 1906 out
**Response SHA256:** 165753b9daeeb3f0

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics"
**Page:** 11
- **Formatting:** Generally professional, but the numeric columns are not decimal-aligned (e.g., Mean Price and Med. Price). The use of "%" in headers is fine, but "Med. €/m2" should use the Euro symbol (€) or spell out "Euro" consistently.
- **Clarity:** Good. It provides a clear breakdown of the two main samples (Full vs. Identified) and the treatment/control split.
- **Storytelling:** Strong. It immediately establishes the price and size differences between investment and owner-occupier properties, justifying the DDD approach.
- **Labeling:** Clear. Notes explain the "Identified sample" restriction well.
- **Recommendation:** **REVISE**
  - Decimal-align all numeric columns.
  - Standardize currency symbols (use € consistently in headers).
  - Add a "Standard Deviation" row or column for key variables; top journals expect more than just medians/means to assess balance.

### Table 2: "Effect of Rent Control on Property Prices"
**Page:** 16
- **Formatting:** Standard three-line LaTeX table. Very close to journal-ready.
- **Clarity:** High. The progression from simple DiD (Col 1) to the headline DDD (Col 4) is logical.
- **Storytelling:** This is the "money" table of the paper. It shows that the effect is only visible when looking at the triple-difference interaction with controls.
- **Labeling:** Excellent notes. Definitions of "Investment" and "Controls" are precise.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Event Study: Effect of Rent Control on Property Prices by Type"
**Page:** 17
- **Formatting:** The "ggplot2" default look (grey background/white gridlines) is often frowned upon in top-tier journals. AER/QJE prefer a white background with minimal or no gridlines.
- **Clarity:** The overlapping 95% CIs (shaded areas) make it hard to see the individual point estimates. The message "it's flat" is clear, but the visual is "muddy."
- **Storytelling:** Essential for validating parallel trends. However, the author notes that the effect only emerges in the DDD, yet they show two separate DiD event studies. 
- **Labeling:** Good.
- **Recommendation:** **REVISE**
  - Change background to white and remove gridlines.
  - Instead of (or in addition to) separate lines, plot the **DDD coefficients** (the difference between the two lines) as a single event study plot. This more directly tests the paper’s primary identification strategy.
  - Use different line types (solid vs. dashed) rather than just color to ensure accessibility in black-and-white printing.

### Table 3: "City-by-City Triple-Difference Estimates"
**Page:** 18
- **Formatting:** Clean and professional.
- **Clarity:** Very high. It clearly shows Bordeaux and Paris as the drivers.
- **Storytelling:** Crucial for the "heterogeneity" narrative. It prevents the reader from assuming the effect is universal.
- **Labeling:** Well-defined.
- **Recommendation:** **KEEP AS-IS** (Consider merging with Table 4 or moving to a Panel format if space is tight).

### Table 4: "Leave-One-Out Stability of Identified-Sample DDD Estimate"
**Page:** 19
- **Formatting:** Professional.
- **Clarity:** High. The bolding of Bordeaux is helpful.
- **Storytelling:** This confirms Table 3's finding. It might be redundant to have both Table 3 and Table 4 in the main text.
- **Recommendation:** **MOVE TO APPENDIX**
  - The "Bordeaux is the driver" story is already told by Table 3. Table 4 is a robustness check that belongs in the Appendix.

### Table 5: "Size Heterogeneity: Effect by Apartment Size Category (Identified Sample)"
**Page:** 20
- **Formatting:** Clean.
- **Clarity:** High. The monotonic gradient is easy to see.
- **Storytelling:** This is one of the strongest "mechanism" proofs in the paper. 
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Table 6: "Treatment Assignment: Communes and Adoption Dates"
**Page:** 31
- **Formatting:** Good.
- **Clarity:** Necessary for transparency.
- **Storytelling:** Purely descriptive.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 7: "Pre-Treatment Data Availability"
**Page:** 32
- **Formatting:** Clean.
- **Clarity:** Very important given the "identified sample" logic.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Property Price Trends by Treatment Status and Property Type"
**Page:** 34
- **Formatting:** Again, the grey "ggplot" default background should be removed.
- **Clarity:** Four lines make for a cluttered plot.
- **Storytelling:** This is a "raw data" version of Figure 1. 
- **Recommendation:** **REVISE**
  - Use a white background.
  - Consolidate this with Figure 1 or keep in Appendix as a "raw trends" check.

### Figure 3: "Triple-Difference Estimates by City"
**Page:** 35
- **Formatting:** Horizontal forest plot is a great way to show heterogeneity.
- **Clarity:** High.
- **Storytelling:** This is a visual representation of Table 3.
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - Top journals love "Forest Plots" for heterogeneity. This is much more impactful than the raw numbers in Table 3. Swap Table 3 to the appendix and put this in the main text.

### Figure 4: "Leave-One-Out Stability of the Identified-Sample DDD Estimate"
**Page:** 36
- **Clarity:** Clear, but redundant with Table 4.
- **Recommendation:** **REMOVE**
  - Between Table 3, Table 4, and Figure 3, the "Bordeaux driver" point is made three times. This figure is the least informative of the group.

### Figure 5: "Randomization Inference: Distribution of Placebo DDD Coefficients"
**Page:** 37
- **Formatting:** Professional histogram.
- **Clarity:** High.
- **Storytelling:** Essential for small-cluster inference robustness.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Investment-Type Transaction Share Over Time"
**Page:** 38
- **Clarity:** Very clean.
- **Storytelling:** Important for ruling out "selection into selling" as a confounder.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 5 main tables, 1 main figure, 2 appendix tables, 5 appendix figures.
- **General quality:** High. The tables follow the "Minimum Ink" principle of the AER. Figures are informative but suffer from "default software" aesthetics (grey backgrounds).
- **Strongest exhibits:** Table 2 (Headline results), Table 5 (Size gradient), Figure 3 (City heterogeneity).
- **Weakest exhibits:** Figure 1 (too much overlap), Figure 4 (redundant).
- **Missing exhibits:** 
    - **Map of France/Cities:** A map showing treated vs. control cities would greatly help international readers (AER/QJE audience) understand the geography.
    - **Coefficient Plot for Table 2:** A summary plot of the different specifications in Table 2 can be more "10-second friendly" than the table itself.

- **Top 3 improvements:**
  1. **Aesthetics:** Remove grey backgrounds and gridlines from all Figures (1, 2, 4, 5, 6) to meet the "look and feel" of top journals.
  2. **Consolidation/Hierarchy:** Move Table 4 (Leave-one-out) to the Appendix and Promote Figure 3 (Forest plot of cities) to the main text. The visual is much more compelling for the heterogeneity story.
  3. **Event Study Clarity:** In Figure 1, add a second panel that plots the **difference** (the DDD coefficient) over time. Currently, the reader has to "eye-ball" the distance between two lines, which is difficult.