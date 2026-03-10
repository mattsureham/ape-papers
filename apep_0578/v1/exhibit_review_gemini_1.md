# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-10T13:47:13.298593
**Route:** Direct Google API + PDF
**Tokens:** 19957 in / 1822 out
**Response SHA256:** 8ed89cf52eb285ab

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: NUTS3 Regions by Treatment Status"
**Page:** 9
- **Formatting:** Professional and clean. Use of horizontal rules is appropriate.
- **Clarity:** Excellent. Provides a clear breakdown of the sample composition (treated, interior, control).
- **Storytelling:** Essential. It establishes the scale of the NUTS3 regions and shows that while GDP levels differ, they are in the same order of magnitude.
- **Labeling:** Clear. Units (EUR, 000s) are well-defined in the notes.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Effect of Schengen Border Controls on Regional Economic Activity"
**Page:** 13
- **Formatting:** High quality. Decimal alignment is generally good. Standard errors in parentheses.
- **Clarity:** Good, though the table is dense. The transition from Column 1 (naïve) to Column 6 (Country x Year) and Column 7 (CS) tells the paper's primary story.
- **Storytelling:** This is the "money table." It successfully shows how the "significant" effect disappears with better controls or robust estimators.
- **Labeling:** Excellent notes explaining the "Implicit" fixed effects in CS.
- **Recommendation:** **REVISE**
  - Group columns using Panel A (GDP Outcomes) and Panel B (Sectoral/Employment) or add a grouping header. 
  - The sample size for Column 4 (Trade GVA) is significantly smaller; add a line in the table body (not just notes) highlighting "Regions" count to make the sample drop-off more visible.

### Figure 1: "Callaway–Sant’Anna Dynamic Event Study: ATT on Log GDP per Capita"
**Page:** 15
- **Formatting:** Clean "ggplot2" style. The dashed vertical and horizontal lines are standard.
- **Clarity:** High. The 10-second takeaway is "flat pre-trend, null post-trend."
- **Storytelling:** Crucial for validating the DiD design.
- **Labeling:** Clear. The note explaining the balanced subsample is important.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Sun–Abraham TWFE Event Study: Log GDP per Capita"
**Page:** 16
- **Formatting:** Consistent with Figure 1.
- **Clarity:** Slightly more cluttered at the tails due to the unbalanced panel.
- **Storytelling:** It serves as a robustness check for Figure 1.
- **Labeling:** Good.
- **Recommendation:** **MOVE TO APPENDIX**
  - Having two event study plots for the same outcome in the main text is redundant for a top journal. Keep Figure 1 (CS) as the primary exhibit and move the Sun-Abraham version to the appendix to declutter the results section.

### Table 3: "Heterogeneity by Border Segment"
**Page:** 17
- **Formatting:** Non-standard for top journals. Reporting separate regressions as rows is usually discouraged in favor of a column-based approach.
- **Clarity:** Clear, but the "N" column refers to observations, not regions, which can be confusing given the text focuses on segments.
- **Storytelling:** Vital for the "mechanisms" story (DE-AT vs. FR-all).
- **Labeling:** "Estimate" should be more specific (e.g., "Coefficient on Border Control").
- **Recommendation:** **REVISE**
  - Convert this to a standard regression table where each border segment is a column. This allows the reader to see the "Regions" count and FE structure more clearly in the footer. Alternatively, merge this with the visual representation in Figure 3.

### Figure 3: "Heterogeneous Effects by Border Segment"
**Page:** 18
- **Formatting:** Good use of a forest plot.
- **Clarity:** Excellent. The $n=x$ labels on the points are very helpful.
- **Storytelling:** This is more effective than Table 3 at showing why the aggregate effect is zero (offsetting coefficients).
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS** (Consider consolidating Table 3 into the notes/labels of this figure).

### Figure 4: "Pre-Treatment Trends in Log GDP per Capita by Region Type"
**Page:** 19
- **Formatting:** Clean. Shaded CIs are readable.
- **Clarity:** Good. It visually confirms that "Control Border" regions are a better level-match than "Interior" regions.
- **Storytelling:** Standard "raw trends" plot. 
- **Labeling:** Legend is clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Robustness of Main TWFE Estimate Across Specifications"
**Page:** 21
- **Formatting:** Vertical forest plot.
- **Clarity:** High.
- **Storytelling:** Efficient way to show that the negative naïve estimate is robust to *everything* except the inclusion of country-by-year FE (which is the paper's point).
- **Labeling:** Labels are descriptive.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Table 4: "Sun–Abraham Event Study Estimates"
**Page:** 31
- **Formatting:** Standard coefficient table.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Robustness Checks for Main TWFE Estimate"
**Page:** 32
- **Recommendation:** **REMOVE**
  - This is a tabular version of Figure 5. In a top journal, you rarely need both. Since Figure 5 is in the main text, this table is redundant even for the appendix.

### Table 6: "Leave-One-Segment-Out Analysis"
**Page:** 33
- **Recommendation:** **KEEP AS-IS** (Though could be visualized as a forest plot).

### Figure 6: "Randomization Inference Distribution"
**Page:** 34
- **Formatting:** Professional histogram. 
- **Clarity:** High. The "True estimate" line is clearly an outlier.
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - Top journals (especially Econometrica/AER) value randomization inference highly when the number of treatment "events" (border segments) is small. This adds significant credibility to the claim that the naïve result was "statistically significant but wrong."

### Figure 7: "Treatment Timing and Border Segments"
**Page:** 35
- **Formatting:** Color-coded bar chart.
- **Clarity:** High.
- **Storytelling:** Great for showing the "staggered" nature and the dominance of the 2015 cohort.
- **Recommendation:** **KEEP AS-IS**

### Table 7: "Standardized Effect Sizes for Main Outcomes"
**Page:** 36
- **Recommendation:** **KEEP AS-IS** (Useful for meta-analysis).

---

## Overall Assessment

- **Exhibit count:** 3 Main Tables, 5 Main Figures, 4 Appendix Tables, 2 Appendix Figures.
- **General quality:** Extremely high. The use of modern DiD visualizations (CS event studies, forest plots for heterogeneity) is exactly what AER/QJE editors look for.
- **Strongest exhibits:** Figure 1 (CS Event Study) and Figure 3 (Heterogeneity Forest Plot).
- **Weakest exhibits:** Table 3 (Row-style regression) and Table 5 (Redundant with Figure 5).
- **Missing exhibits:** **A Map.** For a paper about European borders and NUTS3 regions, a map showing treated vs. control border regions is almost mandatory. It would immediately clarify the "Treatment Assignment" section.

**Top 3 Improvements:**
1. **Add a Map:** Create a choropleth map of Europe highlighting treated NUTS3 regions (by cohort/color), control border regions, and interior regions.
2. **Consolidate Event Studies:** Keep Figure 1 (CS) in the main text; move Figure 2 (Sun-Abraham) to the appendix.
3. **Restructure Table 3:** Transform the row-based heterogeneity table into a standard column-based regression table or rely entirely on Figure 3.