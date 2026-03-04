# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-04T16:58:33.112246
**Route:** Direct Google API + PDF
**Tokens:** 19437 in / 2010 out
**Response SHA256:** bbb5baa1b73a7252

---

This visual exhibit review is based on the standards of top-tier economics journals (AER, QJE, JPE).

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics by MGNREGA Phase"
**Page:** 9
- **Formatting:** Clean, but needs decimal alignment. The numbers in Panel A and B are centered; they should be right-aligned or decimal-aligned to facilitate magnitude comparison.
- **Clarity:** Excellent. The two-column comparison of Phase I vs Phase II clearly shows the "backwardness" selection mechanism.
- **Storytelling:** Essential. It establishes the lack of balance at baseline, justifying the DiD approach and the need for parallel trends.
- **Labeling:** Good. Includes units (kg/ha) and years.
- **Recommendation:** **REVISE**
  - Decimal-align all numeric columns.
  - Add a "Difference (1)-(2)" column with a t-test for balance to formally show the selection bias.

### Table 2: "First Stage: MGNREGA and Agricultural Wages"
**Page:** 13
- **Formatting:** Standard. The "year = X" labeling is a bit clunky for a regression table. 
- **Clarity:** The coefficients for years -8 through 4 are listed vertically. This is difficult to read.
- **Storytelling:** This is the "First Stage." Since the result is a null, it belongs in the paper but perhaps not as a primary table if the focus is on yields.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX** (Replaced by Figure 8).
  - In economics, event-study results are almost always preferred as figures. The table of coefficients for every relative year is redundant if Figure 8 exists.

### Table 3: "MGNREGA and Crop-Specific Yields"
**Page:** 14
- **Formatting:** Too many decimal places in $R^2$ and Within $R^2$. Scientific notation ($3.69 \times 10^{-5}$) is generally avoided in top journals; use "0.000" or similar.
- **Clarity:** Excellent. Spanning the 8 crops in one view allows the reader to see the "null" across the board.
- **Storytelling:** This is the "Money Table." It is the core result.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS** (with minor tweaks to $R^2$ formatting).

### Figure 1: "Crop-Specific Yield Event Studies"
**Page:** 15
- **Formatting:** Professional. Using different colors/shapes for labor-intensive vs. non-labor-intensive is a high-touch detail.
- **Clarity:** 4 panels is the limit for one figure. The y-axis scales differ; it would be better to keep them consistent across panels to show the relative "flatness" of the results.
- **Storytelling:** Strong. It shows the lack of pre-trends and the null effect visually.
- **Labeling:** Good. "Years Relative to MGNREGA Implementation" is clear.
- **Recommendation:** **REVISE**
  - Fix the y-axis range. Currently, Cotton goes from -0.5 to 1.0, while Wheat is -0.1 to 0.3. This masks how much noisier the Cotton data is.

### Figure 2: "Static DiD Estimates by Crop"
**Page:** 16
- **Formatting:** Excellent "Forest Plot" style.
- **Clarity:** Very high. One can immediately see that every 95% CI crosses zero.
- **Storytelling:** This is a "summary" figure. It is slightly redundant with Table 3. 
- **Recommendation:** **KEEP AS-IS** (This is a very "AER" style figure).

### Figure 3: "Heterogeneous Effects: Labor-Intensive vs. Non-Labor-Intensive Crops"
**Page:** 17
- **Formatting:** Clean.
- **Clarity:** The overlapping shaded regions (CIs) make it a bit "busy."
- **Storytelling:** This addresses the primary theoretical mechanism of the paper.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Mechanism: Fertilizer Intensification"
**Page:** 18
- **Formatting:** The relative year coefficients make this table extremely long. 
- **Clarity:** The "post" coefficient in Column 1 is the key result, but it's buried above a long list of relative years in Columns 2-3.
- **Storytelling:** Since this is a "mechanism" check, the static result (Col 1) is more important than the dynamic year-by-year coefficients.
- **Recommendation:** **REVISE**
  - Drop Columns 2 and 3 from this table. Show only the static DiD results for Total Fertilizer, Nitrogen, and Phosphate. Move the event-study coefficients to Figure 4.

### Figure 4: "Mechanism: Fertilizer Intensification After MGNREGA"
**Page:** 19
- **Formatting:** High quality.
- **Clarity:** Shows the "pre-trend instability" mentioned in the text very clearly (the rise before year 0).
- **Storytelling:** Vital for the "honest" reporting of results.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Aggregate Yield Effects of MGNREGA"
**Page:** 20
- **Formatting:** Good.
- **Clarity:** The pink color distinguishes it from the crop-specific results.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Joint Pre-Trend Tests by Crop"
**Page:** 21
- **Formatting:** Standard.
- **Clarity:** Simple summary of Wald tests.
- **Storytelling:** Crucial for robustness.
- **Recommendation:** **MOVE TO APPENDIX**
  - This is a diagnostic table. The results are already visually summarized in Figure 6.

### Table 6: "Robustness: Alternative Specifications for Rice Yield"
**Page:** 21
- **Formatting:** Good use of checkmarks for fixed effects.
- **Clarity:** Clear column headers.
- **Storytelling:** Standard "Top 5" robustness check table.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Table 7: "Crop Labor Intensity Classification"
**Page:** 31
- **Formatting:** Simple text table.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Pre-Trend Test Results by Crop"
**Page:** 32
- **Formatting:** Horizontal bar chart.
- **Clarity:** Much more intuitive than the Table 5 version.
- **Recommendation:** **KEEP AS-IS**

### Figure 7: "Distribution of Districts by MGNREGA Phase"
**Page:** 33
- **Clarity:** Very simple bar chart. 
- **Storytelling:** Low value. This information is already in the first row of Table 1 (N=200, N=111).
- **Recommendation:** **REMOVE** (Redundant with Table 1).

### Figure 8: "First Stage Event Study"
**Page:** 34
- **Formatting:** Professional.
- **Storytelling:** This is more important than the table version (Table 2).
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - Readers usually want to see the first stage in the main body to evaluate the "bite" of the treatment.

---

## Overall Assessment

- **Exhibit count:** 5 main tables, 5 main figures, 1 appendix table, 3 appendix figures.
- **General quality:** Extremely high. The use of modern "clean" ggplot2-style figures and standard Stata/fixest table outputs makes this look like a contemporary NBER working paper.
- **Strongest exhibits:** Figure 2 (Forest Plot) and Table 3 (Crop Spanning).
- **Weakest exhibits:** Table 2 and Table 4 (too many rows of coefficients).

- **Missing exhibits:** 
  - **Map of Treatment Rollout:** A map of India showing Phase I and Phase II districts is standard and expected for this type of paper to visualize spatial clustering and the "backwardness" logic.
  - **Raw Data Plot:** A simple plot of average yields over time for Phase I vs Phase II (not residuals, just raw means) would help the reader see the data before the FE transformations.

- **Top 3 improvements:**
  1. **Convert long coefficient tables (Table 2, Table 4) to figures.** Main text tables should focus on the "Post" coefficient; relative year coefficients are better visualized as event-study plots.
  2. **Standardize y-axes in Figure 1.** Using different scales for different crops is misleading when the paper's argument is that the effect is "zero" for everyone.
  3. **Add a Map.** Visualizing the staggered rollout is essential for an India-based development paper.