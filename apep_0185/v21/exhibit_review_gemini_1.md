# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-05T17:21:42.328110
**Route:** Direct Google API + PDF
**Tokens:** 29317 in / 2192 out
**Response SHA256:** 5b148891e99c00ba

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Figure 1: "Population-Weighted Network Minimum Wage Exposure by County"
**Page:** 12
- **Formatting:** Excellent. Professional map layout with a clean legend.
- **Clarity:** High. The color ramp clearly distinguishes the variation in exposure.
- **Storytelling:** Vital for establishing the "treatment" variation. It shows that even within states (like Texas), there is significant variation in network exposure to high-wage areas.
- **Labeling:** Legend is clear. Subtitle explains the "Darker = stronger" intuition well.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Population-Weighted Minus Probability-Weighted Exposure Gap"
**Page:** 13
- **Formatting:** Professional. The diverging color scale (red/blue) is appropriate for a difference measure.
- **Clarity:** Good. It highlights where the author's methodological innovation (population weighting) deviates most from the standard literature.
- **Storytelling:** Essential for justifying why the "scale" of connections matters.
- **Labeling:** Clear axis/legend.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Within-State Residual Variation in the Instrumental Variable"
**Page:** 14
- **Formatting:** Dual-panel map. Consistent with top journals.
- **Clarity:** Slightly cluttered due to the small size of the panels. 
- **Storytelling:** This is the most important figure for identification. It proves that after state fixed effects, there is still enough "residual" variation to identify the effect.
- **Labeling:** Clear panel titles.
- **Recommendation:** **REVISE**
  - Increase the size of the maps by placing Panel A and Panel B vertically rather than horizontally, or widen the margins for this page.

### Figure 4: "First Stage: Out-of-State vs. Full Network Exposure"
**Page:** 18
- **Formatting:** Standard bin-scatter. Clean gridlines.
- **Clarity:** High. The slope and F-stat are immediately visible.
- **Storytelling:** Supports the relevance condition of the IV.
- **Labeling:** Excellent inclusion of the slope and F-statistic directly in the plot area.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Distance-Credibility Tradeoff"
**Page:** 21
- **Formatting:** Dual-axis plot.
- **Clarity:** A bit busy. Having both First-Stage F and p-values on different scales can be confusing for a quick glance.
- **Storytelling:** Excellent. It visualizes the "sweet spot" for the instrument (100–250km).
- **Labeling:** Legend is clear.
- **Recommendation:** **REVISE**
  - Add a vertical shaded region (a "rect") highlighting the 100–250km "Sweet Spot" discussed in the text to guide the reader's eye.

### Figure 6: "Pre-Treatment Employment Trends by IV Quartile"
**Page:** 22
- **Formatting:** Standard parallel trends plot.
- **Clarity:** Colors are distinguishable. The "Fight for $15" vertical line is a great touch.
- **Storytelling:** Validates the parallel trends assumption.
- **Labeling:** Y-axis clearly labeled "Mean Log Employment."
- **Recommendation:** **KEEP AS-IS**

### Figure 7: "Employment Response to Network MW Exposure by Age Group"
**Page:** 25
- **Formatting:** Coefficient plot with 95% CIs.
- **Clarity:** Very clean.
- **Storytelling:** Shows the lack of an age gradient, supporting the "information" channel over the "migration" channel.
- **Labeling:** Clear x-axis categories.
- **Recommendation:** **KEEP AS-IS** (Note: Table 5 provides the same data; for top journals, keep both as they serve different reader types.)

### Table 5: "Demographic Heterogeneity: Age Groups"
**Page:** 26
- **Formatting:** Clean Booktabs style. No vertical lines.
- **Clarity:** Logical layout.
- **Storytelling:** Complements Figure 7.
- **Labeling:** Significance stars and SE notes are present.
- **Recommendation:** **KEEP AS-IS**

### Figure 8: "Employment Response to Network MW Exposure by Education Level"
**Page:** 27
- **Formatting:** Coefficient plot.
- **Clarity:** High.
- **Storytelling:** The "Education Gradient" is a key result. 
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Demographic Heterogeneity: Education Levels"
**Page:** 27
- **Formatting:** Professional.
- **Clarity:** High.
- **Storytelling:** Necessary numeric backup for Figure 8.
- **Recommendation:** **KEEP AS-IS**

### Figure 9: "Employment Response to Network MW Exposure by Industry Sector"
**Page:** 28
- **Formatting:** Horizontal coefficient plot.
- **Clarity:** Excellent. Ordering by magnitude is the correct choice.
- **Storytelling:** Shows the unexpected result that effects are widespread, not just in "high-bite" sectors.
- **Labeling:** Color-coded for "MW-intensive" is very helpful.
- **Recommendation:** **KEEP AS-IS**

### Table 7: "Sector Heterogeneity: 2SLS by NAICS Sector"
**Page:** 29
- **Formatting:** Professional.
- **Clarity:** Easy to read.
- **Storytelling:** Numeric detail for Figure 9.
- **Recommendation:** **MOVE TO APPENDIX**
  - Figure 9 is so clear that the full 20-row table in the main text feels like "data dump." The main text should focus on the story; the table is for the "robustness" reader.

### Figure 10: "Heterogeneity by Census Division"
**Page:** 33
- **Formatting:** Clean coefficient plot.
- **Clarity:** High.
- **Storytelling:** Shows the geographic "Information" channel (effects are largest where wages were lowest).
- **Recommendation:** **KEEP AS-IS**

### Table 1: "Network Minimum Wage Exposure and Local Labor Market Outcomes"
**Page:** 43
- **Formatting:** Masterful use of panels (Panel A and B). Decimal aligned.
- **Clarity:** Dense but logically organized.
- **Storytelling:** This is the "Money Table." It has OLS, IV, distance tests, and the probability-weighting test all in one.
- **Labeling:** Notes are comprehensive.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "USD-Denominated Specifications: 2SLS Estimates"
**Page:** 44
- **Formatting:** Very clean.
- **Clarity:** High.
- **Storytelling:** Provides the most "quote-able" results for the abstract (the 3.4% and 9% figures).
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Table 3: "Shock Contribution Diagnostics"
**Page:** 44
- **Formatting:** Professional.
- **Clarity:** Clear ranking of states.
- **Storytelling:** Crucial for shift-share (Bartik) designs to show that no single state (e.g., California) is driving 100% of the result.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Balance Tests: Pre-Period Characteristics by IV Quartile"
**Page:** 45
- **Formatting:** Standard balance table.
- **Clarity:** High.
- **Recommendation:** **KEEP AS-IS**

### Table 8: "Job Flow Mechanism: Effects of Network Exposure on Labor Market Dynamics"
**Page:** 45
- **Formatting:** Professional.
- **Clarity:** Multi-column (OLS and 2SLS).
- **Storytelling:** Proves the "churn" mechanism. 
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - This is not just robustness; it's the primary evidence for the *mechanism* (Section 10). It belongs near the Job Flow discussion in the main text.

### Table 9: "Distance-Credibility Analysis..."
**Page:** 48
- **Formatting:** Detailed.
- **Storytelling:** The data behind Figure 5.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 4 Main Tables, 10 Main Figures, 8 Appendix Tables, 1 Appendix Figure.
- **General quality:** Extremely high. The paper follows modern "Top-5" journal conventions (AER/QJE), particularly in its use of binned scatters, coefficient plots, and panel-structured tables.
- **Strongest exhibits:** Table 1 (The definitive results table) and Figure 9 (Industry gradient).
- **Weakest exhibits:** Figure 3 (Maps are too small) and Figure 5 (Dual axis is a bit messy).
- **Missing exhibits:** A **Summary Statistics** table (Means, SDs, Min, Max for main variables) is surprisingly missing from the main text or early appendix. This is a standard requirement.

**Top 3 improvements:**
1. **Add a Summary Statistics Table:** Include it as Table 1 (moving others down). Readers need to see the "raw" means of county earnings and network exposure.
2. **Re-layout Figure 3:** Stack the maps vertically to allow them to take up the full width of the page. The "Within-state" variation is your identifying assumption—let the reader see it clearly.
3. **Relocate Table 8:** Move the Job Flows table to the main text. The "churn" result is central to the paper's contribution regarding *how* networks transmit shocks.