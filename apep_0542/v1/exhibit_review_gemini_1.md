# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-06T21:20:39.483540
**Route:** Direct Google API + PDF
**Tokens:** 17357 in / 1737 out
**Response SHA256:** 044dd0c5ef585a36

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics by Treatment Group"
**Page:** 9
- **Formatting:** Generally professional. Use of horizontal rules is appropriate (Booktabs style). However, the numerical values for "N" should be comma-separated for readability (e.g., 1,901,416). Decimal alignment for means is good, but the percentage columns should also align on the decimal point.
- **Clarity:** The table effectively highlights the "North-South divide" mentioned in the text. The logic of the rows (Treated, Comparison 1, Comparison 2) is clear.
- **Storytelling:** This is essential for motivating why the naive DiD might fail (the huge level and composition differences). 
- **Labeling:** The note is slightly cut off in the OCR/Display ("PP..." and "Other c..."). Ensure the full note explains that property types do not sum to 100% because "Other" is omitted.
- **Recommendation:** **REVISE**
  - Add thousands separators to the "N" column.
  - Fix the cut-off text in the table notes.
  - Decimal-align the percentage columns.

### Table 2: "Effect of HS2 Phase 2 Cancellation on Property Prices"
**Page:** 13
- **Formatting:** Standard AER/QJE style. Good use of parentheses for standard errors.
- **Clarity:** Clear column headers. The transition from distance rings to "Phase 2 vs 1" is logical.
- **Storytelling:** This is the "hook" table that shows the surprising positive result. It correctly sets up the need for the event study.
- **Labeling:** Significance stars are defined. The outcome variable is clearly labeled as `log_price`.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Event Study: Quarterly Treatment Effects on Log House Prices"
**Page:** 15
- **Formatting:** Professional ggplot2-style with a clean background.
- **Clarity:** The core message (pre-trend convergence and no break at $t=0$) is visible within seconds. The shaded 95% CI is helpful.
- **Storytelling:** This is the most important exhibit in the paper. It successfully "debunks" the findings in Table 2.
- **Labeling:** Excellent use of a red dotted line and text annotation ("Cancellation announced"). The x-axis label is descriptive.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Treatment Effect by Distance to Nearest Cancelled Station"
**Page:** 16
- **Formatting:** Consistent with Figure 1. 
- **Clarity:** Shows the "inverted gradient" mentioned in the text (the effect grows as you move further from the station).
- **Storytelling:** Supports the regional trend argument.
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - The x-axis categories "0-2km", "2-5km", etc., are clear, but the ">20km" dot sits on the zero line by construction (it's the reference). It might be cleaner to label it as "Reference Group (>20km)" or omit the point entirely if it’s just a dot at zero with no CI.

### Figure 3: "Treatment Effects by Cancelled Station"
**Page:** 17
- **Formatting:** Horizontal bar chart of coefficients.
- **Clarity:** Good for showing the null result is uniform across all cities.
- **Storytelling:** Strengthens the case that this isn't driven by one specific "noisy" city like Manchester.
- **Labeling:** Y-axis labels (station names) are clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Treatment Effects by Property Type"
**Page:** 18
- **Formatting:** Consistent.
- **Clarity:** Displays heterogeneity.
- **Storytelling:** Shows that the "positive" effect isn't concentrated in rail-sensitive types (flats), which would have supported a causal story.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Robustness Checks and Placebo Tests"
**Page:** 19
- **Formatting:** Good use of checkmarks for fixed effects.
- **Clarity:** Logical grouping of disparate tests.
- **Storytelling:** Essential "stress test" table. Column 3 (Temporal Placebo) is the "killer" evidence alongside the event study.
- **Labeling:** Notes are comprehensive.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Eastern vs. Western Leg Treatment Effects"
**Page:** 20
- **Formatting:** Clean.
- **Clarity:** High.
- **Storytelling:** Tests if the 2021 signal changed anything. Since the results are the same, it supports the "no anticipation" or "regional trend" story.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**
  - The paper already has a lot of heterogeneity figures (Figures 2, 3, and 4). This table is a bit niche for the main text and could be summarized in one sentence or moved to an Appendix.

### Figure 5: "Randomization Inference: Distribution of Permuted Treatment Effects"
**Page:** 21
- **Formatting:** Standard histogram.
- **Clarity:** Shows the observed effect is a "statistical" outlier even if it's not "causal."
- **Storytelling:** A bit technical. 
- **Labeling:** Red line is clear.
- **Recommendation:** **MOVE TO APPENDIX**
  - Randomization inference is great for robustness, but given the massive pre-trend failure, the "statistical significance" of the DiD coefficient is already secondary. This belongs in the Appendix.

---

## Appendix Exhibits

### Figure 6: "Raw Price Trends: Treated vs. Control Areas"
**Page:** 31
- **Formatting:** Clean line plot.
- **Clarity:** Shows the level differences and the closing gap.
- **Storytelling:** High. This is the raw data version of Figure 1.
- **Labeling:** Legible.
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - In top-tier journals (especially AEJ: Policy), showing the "raw" trends before the "estimated" event study is standard practice and builds trust. Place this near Table 1 or before Figure 1.

---

## Overall Assessment

- **Exhibit count:** 4 Main Tables, 5 Main Figures, 0 Appendix Tables, 1 Appendix Figure.
- **General quality:** Extremely high. The exhibits look like they belong in a top-tier journal (clear fonts, no gridlines, professional color palette).
- **Strongest exhibits:** Figure 1 (Event Study) and Table 3 (Robustness).
- **Weakest exhibits:** Figure 2 (reference point looks awkward) and Figure 5 (too specialized for main text).
- **Missing exhibits:** 
    1. **Map:** A paper about a 200km infrastructure project *needs* a map showing Phase 1, Phase 2, and the treatment rings.
    2. **Balance Table:** While Table 1 shows means, a column showing the "Difference" or a "Pre-trend slope" would be helpful.
- **Top 3 improvements:**
  1. **Add a Map:** Create a figure showing the geography of HS2 and the transactions.
  2. **Re-organize Flow:** Promote Figure 6 (Raw Trends) to the main text and move Figure 5 (Randomization Inference) and Table 4 (Legs) to the Appendix to keep the main story punchy.
  3. **Visual Polish:** Fix the truncated text in Table 1's notes and add thousands separators to large numbers in all tables.