# Exhibit Review — Gemini 3 Flash (Round 3)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-04T11:02:46.540385
**Route:** Direct Google API + PDF
**Tokens:** 20477 in / 2050 out
**Response SHA256:** 2fd8e93495520340

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Property Transactions Near REP/Non-REP Boundaries"
**Page:** 13
- **Formatting:** Clean and professional. Good use of horizontal rules (booktabs style).
- **Clarity:** High. Provides a clear comparison between the two groups.
- **Storytelling:** Essential. It establishes the "raw" 21% price gap ($4,147 vs $3,274) which the rest of the paper seeks to explain away via sorting.
- **Labeling:** Clear. Units (Euros/m²) are defined in the notes but would be better in the column header.
- **Recommendation:** **KEEP AS-IS** (Minor: move units to headers).

### Figure 1: "Property Prices at Education Priority Zone Boundaries"
**Page:** 16
- **Formatting:** Standard RDD plot. The loess fit is appropriate, but the confidence shading is quite wide at the edges. 
- **Clarity:** The key message (a jump at the boundary) is visible, but the scale of the Y-axis (7.6 to 8.2 in logs) makes the jump look smaller than the 5.3% estimate suggests. 
- **Storytelling:** This is the "money plot" for the nonparametric result. However, the downward trend on both sides suggests strong spatial correlation that necessitates the geographic fixed effects introduced later.
- **Labeling:** Good. "Distance to Boundary (meters)" is clear.
- **Recommendation:** **REVISE**
  - Increase the font size of axis titles.
  - Add a vertical label at $X=0$ explicitly stating "REP Side" (right) vs "Non-REP Side" (left) to assist quick parsing.
  - Consider a slightly narrower X-axis window (e.g., +/- 1000m) to make the discontinuity at zero more prominent.

### Table 2: "Main Results: Parametric Boundary Estimates"
**Page:** 19
- **Formatting:** Standard `fixest` output. Good decimal alignment.
- **Clarity:** Excellent. The progressive addition of FE (Columns 1–5) tells the core story of the paper: the coefficient moving from -0.14 to 0.00.
- **Storytelling:** This is the most important table in the paper. It successfully "kills" the stigma effect by controlling for sorting.
- **Labeling:** Proper significance codes and standard errors in parentheses. 
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Annual Boundary Gaps: REP/Non-REP Price Discontinuity by Year"
**Page:** 20
- **Formatting:** Clean line plot with confidence intervals.
- **Clarity:** High. Shows a clear downward trend in the boundary gap over time.
- **Storytelling:** Supports the "Time Dynamics" section. It suggests the REP label is becoming less of a negative signal or that resources (dédoublement) are starting to capitalize positively.
- **Labeling:** The x-axis "2025 (partial)" label is slightly crowded.
- **Recommendation:** **REVISE**
  - Add a horizontal dashed line at 0.000 (currently there, but make it darker) to emphasize that 2024/2025 are approaching or crossing zero.

### Figure 3: "Transaction Density at REP/Non-REP Boundaries"
**Page:** 21
- **Formatting:** Standard McCrary-style histogram.
- **Clarity:** The huge spike at zero is visually alarming for a "clean" RDD but effectively proves the author's point that sorting is rampant.
- **Storytelling:** Crucial for the "Threats to Identification" section. It honestly displays why a simple RDD fails here.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Covariate Balance at REP/Non-REP Boundaries"
**Page:** 22
- **Formatting:** Clean, simple 4-column layout.
- **Clarity:** High.
- **Storytelling:** Provides the statistical evidence for Figure 4. It proves that "all else is NOT equal" at the boundary.
- **Labeling:** Units included.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Covariate Smoothness at REP/Non-REP Boundaries"
**Page:** 22
- **Formatting:** Dual-panel figure. 
- **Clarity:** Binned means are clear. The discontinuity in "Share Apartments" is very obvious.
- **Storytelling:** This justifies the inclusion of property-level controls in Table 2.
- **Labeling:** Y-axis labels are clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Bandwidth Sensitivity of Boundary Estimates"
**Page:** 23
- **Formatting:** Standard RDD robustness check.
- **Clarity:** High. Shows the estimate is stable regardless of bandwidth choice.
- **Storytelling:** Necessary for Econometrica/AER-level rigor, but less "exciting" than the main results.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX** (The text on p. 23 already summarizes the stability well; the plot is standard robustness fodder).

### Table 4: "Robustness: Bandwidth Sensitivity and Donut Specifications"
**Page:** 24
- **Formatting:** Panel structure is good.
- **Clarity:** Panel B is particularly striking, showing the effect disappears once you move 100m away.
- **Storytelling:** Important for showing the effect is extremely localized.
- **Labeling:** Neff (Effective N) is a good addition.
- **Recommendation:** **REVISE**
  - Merge the content of Figure 5 into this table as "Panel A" (which it already is) and keep the table. A single table is more efficient than having Figure 5 and Table 4 separate.

### Figure 6: "REP Boundary Gap by Private School Availability"
**Page:** 26
- **Formatting:** Overlapping loess fits. The color contrast (red vs blue) is good.
- **Clarity:** This is a complex plot. The fact that "High Private Density" (blue) sits much higher in price but has a flatter/reversed slope is the key.
- **Storytelling:** This provides the mechanism. It's the strongest "Economic" result after the main null.
- **Labeling:** The legend "Private School Availability" is placed inside the plot area, which is fine, but ensure it doesn't obscure data points.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Table 5: "Placebo Tests at Shifted Boundary Locations"
**Page:** 36
- **Formatting:** Simple and clean.
- **Clarity:** High.
- **Storytelling:** Shows that you find "effects" even where there is no boundary, which further invalidates the naive RDD.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Year-by-Year RDD Estimates at REP/Non-REP Boundaries"
**Page:** 37
- **Formatting:** Standard.
- **Clarity:** High.
- **Storytelling:** This is the numerical version of Figure 2.
- **Labeling:** Clear.
- **Recommendation:** **REMOVE** (Redundant with Figure 2. Top journals prefer the visual for trends; the point estimates for each year aren't central enough to require a separate table if the figure exists).

---

## Overall Assessment

- **Exhibit count:** 3 main tables, 5 main figures, 2 appendix tables, 0 appendix figures.
- **General quality:** Extremely high. The paper follows the "Gold Standard" for modern applied micro (specifically RDD papers). The exhibits transition logically from "Raw Fact" to "Causal Identification Problem" to "Robust Solution."
- **Strongest exhibits:** Table 2 (Main Results) and Figure 6 (Private School Mechanism).
- **Weakest exhibits:** Figure 5 (standard/boring) and Table 6 (redundant).
- **Missing exhibits:** 
    1. **Map of France:** A geocoded paper using 1.7M observations needs a heat map showing the density of REP schools and transactions. This helps the reader visualize the Paris vs. Provinces distinction mentioned on Page 25.
    2. **Balance Table for FE:** A table showing that covariates *become* balanced once commune fixed effects are applied would be a powerful "closer" for the identification argument.
- **Top 3 improvements:**
  1. **Add a Geography Figure:** A map showing the REP/Non-REP school locations and the 2km boundary buffers. This is standard for "spatial" papers in the QJE/AER.
  2. **Consolidate Robustness:** Move Figure 5 (Bandwidth) to the appendix and rely on Table 4 in the main text to save "real estate" and improve flow.
  3. **Enhance Figure 1:** Add clear "REP" and "Non-REP" text labels directly onto the plot area to make the 10-second parse easier for a skimming editor.