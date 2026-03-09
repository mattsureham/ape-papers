# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-09T14:32:07.486683
**Route:** Direct Google API + PDF
**Tokens:** 23077 in / 2085 out
**Response SHA256:** ed0d50ebb2e476ec

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "DPE Rating Thresholds (Post-2021 Methodology)"
**Page:** 8
- **Formatting:** Clean, professional, and consistent with AER/QJE styles. Good use of horizontal rules (booktabs style).
- **Clarity:** Excellent. The mapping from letter grades to technical units is immediately clear.
- **Storytelling:** Essential institutional background. It justifies the RDD cutoffs used later in the paper.
- **Labeling:** Clear. Units (kWh/m²/year) are properly specified.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Summary Statistics"
**Page:** 13
- **Formatting:** Standard professional layout. 
- **Clarity:** Good, though the inclusion of every DPE category (A through G) is a bit long. 
- **Storytelling:** Establishes the sample size and the rarity of "A" and "B" rated properties. 
- **Labeling:** Note explains binary variable SD calculation. However, "Post-reform (%)" is slightly ambiguous—does it mean 78% of the *transactions* occurred post-reform? (Yes, but should be explicit).
- **Recommendation:** **REVISE**
  - Group the DPE ratings to show the primary groups of interest (Passoires vs. Safe) more prominently at the top of that section of the table.

### Table 3: "Effect of DPE G-Rating on Property Prices"
**Page:** 16
- **Formatting:** Professional. Standard errors are correctly in parentheses.
- **Clarity:** Logical progression from column (1) to (3). 
- **Storytelling:** This is the core "hook" of the paper. It shows the 2% discount (Column 3) which is the most robust result.
- **Labeling:** Good. Significance stars are defined. "Num.Obs." is standard.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Dynamic Treatment Effect of G-Rating on Property Prices"
**Page:** 18
- **Formatting:** High quality. Shaded confidence intervals are clean. The vertical red dashed line for the reform is standard and helpful.
- **Clarity:** Very high. The "delay" and "reversion" are immediately visible.
- **Storytelling:** Vital for testing parallel trends and showing the timing of the market response.
- **Labeling:** Clear. Y-axis specifies "Log Price Difference."
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "G-Rating Discount by Commune Rental Share"
**Page:** 19
- **Formatting:** A bit cluttered. The confidence interval "envelope" is very wide and irregular at the right end, which distracts from the message.
- **Clarity:** Low. The message (a flat or slightly positive trend) is buried in noise. The decile dots don't follow a clear pattern.
- **Storytelling:** This exhibit actually hurts the paper's argument by highlighting the "failure" of the triple-difference.
- **Recommendation:** **MOVE TO APPENDIX**
  - The text already admits this design is "imprecisely estimated." Moving this to the appendix prevents the reader from getting stuck on a null/noisy result in the main text.

### Table 4: "Regulatory vs. Informational Channel: Triple-Difference by Rental Share"
**Page:** 20
- **Formatting:** Professional.
- **Clarity:** The coefficients for triple interactions are notoriously hard to read. 
- **Storytelling:** Important for the attempt to decompose the effect, even if results are null.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS** (but consider moving to Appendix if space is tight, as the results are insignificant).

### Table 5: "Multi-Cutoff RDD: Price Discontinuity at DPE Thresholds"
**Page:** 21
- **Formatting:** Clean tabular format for RDD results.
- **Clarity:** The "Rental Ban" column is a great addition for context.
- **Storytelling:** Strongly supports the "salience" argument by showing the effect is largest where the ban is most imminent.
- **Labeling:** Excellent.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Regression Discontinuity at the G/F Threshold (420 kWh/m²/year)"
**Page:** 22
- **Formatting:** Modern and clean. Binned scatter points with fit lines.
- **Clarity:** High. Shows the noise but also the slight step-down.
- **Storytelling:** Standard for RDD papers.
- **Labeling:** Clear axis and threshold labels.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Difference-in-Discontinuities at the G/F Threshold"
**Page:** 23
- **Formatting:** Professional.
- **Clarity:** Hard to parse the interaction "Above 420 x Post-Reform" as the main effect without more guidance in the note.
- **Storytelling:** Redundant with Table 3 and Table 5.
- **Recommendation:** **MOVE TO APPENDIX**

### Table 7: "Placebo RDD: Pre-Reform vs. Post-Reform at the G/F Threshold"
**Page:** 24
- **Formatting:** Good.
- **Clarity:** Very clear contrast.
- **Storytelling:** Essential for RDD validity.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Distribution of Energy Consumption Near the G/F Threshold"
**Page:** 25
- **Formatting:** Clean histogram.
- **Clarity:** The "bunching" just below the red line is visible.
- **Storytelling:** This is one of the paper's most novel contributions (evidence of gaming).
- **Labeling:** Descriptive title.
- **Recommendation:** **KEEP AS-IS**

### Table 8: "McCrary Density Tests at DPE Thresholds"
**Page:** 25
- **Formatting:** Simple and effective.
- **Clarity:** The T-statistics tell the story clearly.
- **Storytelling:** Quantitative proof for Figure 4.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "RDD Sensitivity to Bandwidth Choice"
**Page:** 27
- **Formatting:** Standard RDD robustness plot.
- **Clarity:** High. Shows the estimate is stable around -0.015 to -0.02.
- **Storytelling:** Standard robustness.
- **Recommendation:** **MOVE TO APPENDIX** (Standard practice for top journals to put bandwidth sensitivity in the online supplement).

### Table 9: "Robustness: Heterogeneity by Property Type, Urbanicity, and Fixed Effects"
**Page:** 28
- **Formatting:** Professional.
- **Clarity:** Five columns is a lot, but they are logically grouped.
- **Storytelling:** Critical for ruling out alternative explanations (like "only rural properties drive this").
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Table 10: "Donut RDD at the G/F Threshold"
**Page:** 40
- **Recommendation:** **KEEP AS-IS** (Strong robustness check).

### Table 11: "Polynomial Sensitivity of the G/F RDD"
**Page:** 41
- **Recommendation:** **KEEP AS-IS**.

### Table 12: "Standardized Effect Sizes for Main Outcomes"
**Page:** 42
- **Formatting:** Excellent. This is a "Summary of Evidence" table that is becoming more common in top journals.
- **Clarity:** High. It synthesizes the whole paper into one view.
- **Recommendation:** **PROMOTE TO MAIN TEXT** (Place it in the Discussion section to summarize findings).

---

## Overall Assessment

- **Exhibit count:** 8 Main Tables, 5 Main Figures, 3 Appendix Tables.
- **General quality:** Extremely high. The figures use a modern, clean aesthetic (likely ggplot2/R) that is very readable. Tables follow the `booktabs` style preferred by top-tier journals.
- **Strongest exhibits:** Figure 1 (Event Study) and Figure 4 (Density Test). They tell the two most important stories of the paper (capitalization and gaming).
- **Weakest exhibits:** Figure 2 (Triple-Diff visualization) is too noisy and undermines the narrative.
- **Missing exhibits:** 
    - **A Balance Table:** An RDD paper usually needs a table showing that covariates (surface area, rooms) are smooth across the threshold.
    - **Map of France:** A heat map showing where "Passoires" are concentrated vs. where the sample transactions are located would add significant "real-world" flavor.

### Top 3 Improvements:
1. **Move Figure 2 and Table 6 to the Appendix.** The main text is currently exhibit-heavy. Removing the noisier results streamlines the "2% discount" story.
2. **Add an RDD Balance Table.** Show that "Surface" and "Rooms" don't jump at 420 kWh. This is a standard requirement for Econometrica or QJE.
3. **Promote Table 12 (Effect Sizes) to the main text.** It acts as a perfect executive summary for a reader who only has 60 seconds to understand the paper's various identification strategies.