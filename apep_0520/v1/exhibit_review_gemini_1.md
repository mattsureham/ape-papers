# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-05T16:22:54.461147
**Route:** Direct Google API + PDF
**Tokens:** 17877 in / 2053 out
**Response SHA256:** 9c70383898e9444d

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Pre-Treatment Period (January–June 2018)"
**Page:** 10
- **Formatting:** Clean, professional layout using booktabs style. Number alignment is generally good, though decimals for "BH Paid" and "SUD Paid" are unnecessary given the scale.
- **Clarity:** Excellent. Provides a clear snapshot of the baseline before waiver adoption.
- **Storytelling:** Essential. It establishes the "size" of the Medicaid behavioral health market.
- **Labeling:** Definitions for BH, SUD, and MAT in the notes are helpful.
- **Recommendation:** **REVISE**
  - Drop decimals for the "Paid ($)" rows; they add clutter without information.
  - Add a "Number of States" or "N" count to the header or notes to clarify the cross-sectional units.

### Figure 1: "SUD-Specific Provider Supply"
**Page:** 13
- **Formatting:** Modern ggplot style. The use of a shaded confidence interval and a vertical treatment line is standard for top journals.
- **Clarity:** The "marginally significant decline" is the key message. The y-axis "ATT (Log SUD Providers)" is clear.
- **Storytelling:** This is a "hook" exhibit—it shows a surprising result (a decline) that justifies the subsequent decomposition.
- **Labeling:** Good descriptive subtitle.
- **Recommendation:** **REVISE**
  - The y-axis scale (-1.0 to 0.5) is slightly wide given the data; tightening it might help visibility.
  - Remove the internal plot title ("Effect on SUD-Specific...") as it is redundant with the figure caption.

### Table 2: "Main Results: Effect of 1115 SUD Waivers on Provider Supply"
**Page:** 14
- **Formatting:** Professional. Columns are well-ordered.
- **Clarity:** Very high. One can see the coefficients and p-values across all primary outcomes at once.
- **Storytelling:** This is the "money table." It centralizes the paper's core findings. 
- **Labeling:** The inclusion of the "% Change" column is an excellent touch for readability.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Main Result: Effect of 1115 SUD Waivers on BH Provider Supply"
**Page:** 14
- **Formatting:** Consistent with Figure 1.
- **Clarity:** Clearly shows the noisy but positive trend.
- **Storytelling:** Necessary to contrast with Figure 1.
- **Labeling:** "Never-treated states as controls" in notes is a vital methodological detail.
- **Recommendation:** **REVISE**
  - Consolidate: Figures 1, 2, and 3 are all individual event studies. Consider merging them into Figure 4 (the multi-panel) and making *that* the primary figure to save space and allow direct comparison.

### Figure 3: "Placebo Test: Personal Care Providers (T-codes)"
**Page:** 15
- **Formatting:** Standard.
- **Clarity:** Shows a flat line as expected.
- **Storytelling:** Crucial for internal validity.
- **Labeling:** Good.
- **Recommendation:** **MOVE TO APPENDIX** 
  - While important, the placebo result is summarized in Table 2. The visual plot is better suited for the appendix unless the author believes the "flatness" needs to be proven to skeptical reviewers.

### Figure 4: "Multi-Panel Event Study: Treatment and Placebo Outcomes"
**Page:** 16
- **Formatting:** Excellent use of facets.
- **Clarity:** This is the most efficient way to view the results. 
- **Storytelling:** Extremely strong. It allows the reader to see the "divergent" stories of BH vs. SUD providers simultaneously.
- **Recommendation:** **KEEP AS-IS** (And consider moving this to replace Figures 1-3).

### Figure 5: "Mechanism: Extensive Margin (Entry) and Intensive Margin (Access)"
**Page:** 17
- **Formatting:** Consistent with other figures.
- **Clarity:** Very clear.
- **Storytelling:** Supports the "Why no supply response?" discussion by showing the channels are empty.
- **Labeling:** Clear panel titles.
- **Recommendation:** **REVISE**
  - Change colors for the two panels to distinguish "Entry" from "Access" visually.

### Table 3: "Robustness Checks: BH Provider Supply"
**Page:** 19
- **Formatting:** Professional.
- **Clarity:** Shows that the result is sensitive to estimator choice (CS-DiD vs. TWFE), which is an honest and important academic contribution.
- **Storytelling:** Essential for the current "DiD Revolution" climate in top journals.
- **Labeling:** Notes clearly define the specifications.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Estimator Comparison: CS-DiD vs. Stacked Cohort DiD"
**Page:** 19
- **Formatting:** Overlaid event studies.
- **Clarity:** Can be a bit "busy" with two sets of intervals.
- **Storytelling:** Directly supports the discussion of why CS-DiD gives a different result than standard TWFE.
- **Recommendation:** **REVISE**
  - Use different line types (dashed vs. solid) in addition to color to ensure the lines are distinguishable in grayscale printing.

### Figure 7: "Randomization Inference: BH Provider Supply"
**Page:** 20
- **Formatting:** Standard histogram.
- **Clarity:** Clearly shows the observed estimate in the center of the null distribution.
- **Storytelling:** Standard robustness for DiD papers.
- **Recommendation:** **MOVE TO APPENDIX**
  - The RI p-value is already in Table 3. The plot is standard and doesn't need main-text space.

### Figure 8: "Raw Trends: BH Providers by Treatment Status"
**Page:** 22
- **Formatting:** The drop at the end of 2024 is likely a data reporting lag/incomplete data issue.
- **Clarity:** The secular upward trend is obvious.
- **Storytelling:** Important to show what the raw data looks like before the "DiD machinery" is applied.
- **Labeling:** Needs a note explaining the 2024 drop (likely "right-censoring" of claims processing).
- **Recommendation:** **REVISE**
  - Add a vertical line at the median treatment year to help the reader "eyeball" the DiD.

---

## Appendix Exhibits

### Table 4: "Section 1115 SUD Waiver Adoption Timeline"
**Page:** 30
- **Formatting:** Simple and effective.
- **Clarity:** High.
- **Storytelling:** Provides the "map" of the identification strategy.
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - Readers of AER/QJE want to see the treatment variation early. This could be a small table in the Institutional Background section.

### Figure 9: "Bacon Decomposition: 2x2 DiD Weights"
**Page:** 31
- **Formatting:** Standard scatter from the `bacondecomp` package.
- **Clarity:** Good for specialists.
- **Storytelling:** Explains the TWFE bias.
- **Recommendation:** **KEEP AS-IS**

### Figure 10: "Per Capita Event Study: BH Providers per 100,000 Population"
**Page:** 32
- **Formatting:** Consistent.
- **Storytelling:** Proves the result isn't driven by population denominators.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 3 main tables, 8 main figures, 1 appendix table, 2 appendix figures.
- **General quality:** High. The paper uses the "new" DiD toolkit (Callaway-Sant'Anna, Bacon, Stacked) and the visualizations reflect this modern standard.
- **Strongest exhibits:** Table 2 (comprehensive results) and Figure 4 (multi-panel view).
- **Weakest exhibits:** Figures 1, 2, and 3 (too much repetition/spacing used for single-plot figures).
- **Missing exhibits:** 
    - **A Map:** A choropleth map of the US showing "Early Adopters," "Late Adopters," and "Never Treated" would be highly effective for a North American audience.
- **Top 3 improvements:**
  1. **Consolidate Figures:** Merge Figures 1, 2, and 3 into a single high-impact multi-panel figure (or use Figure 4) to improve the "information density" of the main text.
  2. **Promote the Timeline:** Move Table 4 (Adoption Timeline) to the main text to establish the identification variation immediately.
  3. **Address the "2024 Drop":** Figure 8 shows a sharp drop at the end of the sample. The author must add a note to the figure explaining if this is a "claims lag" (incomplete reporting for the most recent months) to avoid appearing like a data error.