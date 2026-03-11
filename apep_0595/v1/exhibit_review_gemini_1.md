# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-11T10:35:28.576493
**Route:** Direct Google API + PDF
**Tokens:** 19957 in / 1749 out
**Response SHA256:** 7f695307895ff982

---

As a visual exhibit advisor for top-tier economics journals, I have reviewed the exhibits in "Trade Protection by Fiat." The paper features a clean, professional aesthetic, but several exhibits require refinement to meet the "gold standard" of the *AER* or *QJE*.

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Rice Prices in Nigerian Markets"
**Page:** 10
- **Formatting:** Good use of booktabs (horizontal lines). However, the indentation for sub-groups is a bit shallow.
- **Clarity:** Clear, but the "Full Sample" and "Pre/Post" sections overlap with the "Border/Interior" sections in a way that is slightly confusing.
- **Storytelling:** Essential. It establishes the "well-powered null" by showing near-identical means across groups.
- **Labeling:** Notes are comprehensive.
- **Recommendation:** **REVISE**
  - Add more whitespace or indentation between the global sample and the group-specific (Border vs. Interior) rows.
  - Decimal-align the numbers in the "Mean" and "SD" columns.

### Table 2: "Effect of Border Closure on Rice Prices"
**Page:** 14
- **Formatting:** Standard journal format. Column headers are clear.
- **Clarity:** Excellent. The transition from binary to continuous to bins is logical.
- **Storytelling:** The core of the paper.
- **Labeling:** Significance stars and clustering noted.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Event-Study Estimates: Border Market Differential Price Effect"
**Page:** 15
- **Formatting:** Clean, modern look. The light blue CI band is professional.
- **Clarity:** The message (flat trend) is immediate.
- **Storytelling:** Critical for validating the DiD design.
- **Labeling:** The y-axis label "Coefficient (Log Price)" is accurate. The x-axis "Months Relative to..." is standard.
- **Recommendation:** **REVISE**
  - Increase the font size of the axis labels and ticks. In a printed journal, this text will be very small.
  - The vertical dashed line at "0" is good, but consider adding a secondary label "Closure" directly on the plot.

### Table 3: "Border Closure Effects by Commodity Type"
**Page:** 17
- **Formatting:** Simple and clean.
- **Clarity:** High. Shows the null is robust across different staples.
- **Storytelling:** This is effectively a "robustness" or "extension" table. It could be merged with Figure 2.
- **Recommendation:** **REVISE**
  - Merge the information in this table into the notes or labels of Figure 2 and move the table itself to the Appendix. The figure is more visually arresting for the main text.

### Figure 2: "Border Closure Effects by Commodity Type"
**Page:** 18
- **Formatting:** Consistent with Figure 1.
- **Clarity:** Excellent. 
- **Storytelling:** Briefly summarizes the commodity-wide null.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS** (but consider merging Table 3 data into the caption/notes).

### Figure 3: "Distance Gradient of Border Closure Effects"
**Page:** 20
- **Formatting:** Consistent.
- **Clarity:** Clear, though having only two points makes it look slightly sparse.
- **Storytelling:** Directly addresses the "spatial gradient" prediction of trade models.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Table 4: "Robustness of Main Rice Price Results"
**Page:** 32
- **Formatting:** High-density table. Professional.
- **Clarity:** Great way to summarize 5+ regressions in one view.
- **Storytelling:** Essential for the Appendix.
- **Labeling:** Well-documented specification changes.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Randomization Inference: Distribution of Permuted DiD Coefficients"
**Page:** 33
- **Formatting:** Histogram is clean. The red "Actual estimate" line is excellent storytelling.
- **Clarity:** High.
- **Storytelling:** Convincing proof that the null isn't an artifact of the clustering method.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Leave-One-Market-Out Sensitivity"
**Page:** 34
- **Formatting:** The x-axis labels (Market Names) are rotated and very small. 
- **Clarity:** Low. The x-axis is unreadable without significant zooming.
- **Storytelling:** Shows no single market drives the result.
- **Recommendation:** **REVISE**
  - Group the markets by region/state or simply remove the individual labels and label the x-axis "Excluded Market (N=35)". The specific market names aren't as important as the distribution of the coefficients.

### Figure 6: "Study Design: Market Locations and Price Trends"
**Page:** 35
- **Formatting:** This is actually two separate exhibits (a map and a time-series plot) stacked.
- **Clarity:** The map is abstracted (no borders or coastline). The price trend plot is busy but informative.
- **Storytelling:** This is a "Step 0" exhibit.
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - This figure (the map and the raw price trends) is the most important "Data" exhibit. It should be in Section 3.
  - **Specific Revise:** Add a light outline of Nigeria’s borders and the neighboring countries to the map. Without it, the "distance to border" concept is too abstract for a reader unfamiliar with Nigerian geography.

### Table 5: "Standardized Effect Sizes for Main Outcomes"
**Page:** 36
- **Formatting:** Over-reliance on text in the "Classification" column.
- **Clarity:** A bit cluttered with the long "Notes" section.
- **Storytelling:** This is more of a meta-analysis tool. 
- **Recommendation:** **REMOVE** or move to the very end of the Appendix. It feels like a "working document" table rather than a journal exhibit.

---

## Overall Assessment

- **Exhibit count:** 3 main tables, 3 main figures, 2 appendix tables, 3 appendix figures.
- **General quality:** High. The paper follows the modern "minimalist" aesthetic of the AEA journals. The consistent color palette (Blue/Red) and font choice make the paper feel cohesive.
- **Strongest exhibits:** Figure 1 (Event Study) and Figure 4 (Randomization Inference).
- **Weakest exhibits:** Figure 5 (Jackknife labels are unreadable) and Figure 6 (needs geographic context).
- **Missing exhibits:** 
  1. **A Map with Road Networks:** The author mentions road connectivity in the limitations. A map showing the "smuggling corridors" mentioned in Section 2.2 would be highly impactful.
  2. **First-Stage Table/Figure:** Evidence that formal trade *actually* dropped at the border during the closure (perhaps using COMTRADE or NBS data).

### Top 3 Improvements:
1.  **Contextualize Figure 6:** Add geographic borders to the map and move it to the main text as Figure 1. It is the best way to introduce the data.
2.  **Fix Axis Legibility:** Across all figures, increase font sizes for axis titles and labels by roughly 20-30%. Top journals often shrink figures to fit 2-column or 1.5-column layouts; the current text will vanish.
3.  **Decimal Alignment:** Ensure all tables (especially Table 1 and Table 4) use decimal alignment. It is a subtle but required "AER-look" standard that makes comparing coefficients significantly easier for the reader.