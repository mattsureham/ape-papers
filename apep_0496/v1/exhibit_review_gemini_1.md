# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-04T10:03:45.029172
**Route:** Direct Google API + PDF
**Tokens:** 18397 in / 1681 out
**Response SHA256:** 182444ef29a8bb75

---

This review evaluates the visual exhibits of the paper "The Stigma of Priority: Education Priority Zone Labels and Housing Prices in France" against the standards of top-tier economics journals (AER, QJE, etc.).

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Property Transactions Near REP/Non-REP Boundaries"
**Page:** 12
- **Formatting:** Clean, but uses a non-standard layout. Top-tier journals typically avoid vertical lines and prefer booktabs style (top, middle, and bottom horizontal rules only).
- **Clarity:** Excellent. The comparison between REP and Non-REP sides is immediately clear.
- **Storytelling:** Strong. It sets the stage by showing the raw 21% price gap while establishing that structural characteristics (surface, % apt) are remarkably similar.
- **Labeling:** Good. It defines units (Euros, m2) and the sample restriction.
- **Recommendation:** **REVISE**
  - Remove all vertical lines.
  - Add a "Difference" column with t-statistics to formally show balance/unbalance in this descriptive table.
  - Change "% Apt" to "Share Apartment" to match the text and Figure 4.

### Figure 1: "Property Prices at Education Priority Zone Boundaries"
**Page:** 15
- **Formatting:** Modern and clean. The use of a loess fit with confidence intervals is standard. 
- **Clarity:** High. The discontinuity at zero is visually undeniable.
- **Storytelling:** This is the "money plot" of the paper. It establishes the baseline finding effectively.
- **Labeling:** Clear. Axis labels are descriptive. 
- **Recommendation:** **KEEP AS-IS** (Consider increasing the font size of the axis labels slightly for print readability).

### Table 2: "Main Results: Parametric Boundary Estimates"
**Page:** 17
- **Formatting:** Professional "Stargazer/Fixest" style. Coefficients are well-aligned.
- **Clarity:** Logical progression from Column 1 (naive) to Column 4 (fully controlled).
- **Storytelling:** Crucial. This table "kills" the causal interpretation of the RDD by showing the estimate vanishes with geographic FEs.
- **Labeling:** Detailed notes. Significance stars and SE clustering are correctly noted.
- **Recommendation:** **REVISE**
  - Scientific notation in the distance variables ($10^{-5}$) is difficult to read. Rescale the "Distance to Boundary" variable to kilometers so coefficients are larger and easier to parse.
  - Replace the "I(type_local==...)" row with a cleaner label like "Apartment Indicator".

### Figure 2: "Annual Boundary Gaps: REP/Non-REP Price Discontinuity by Year"
**Page:** 18
- **Formatting:** Clean coefficient plot.
- **Clarity:** Shows a clear downward trend over time.
- **Storytelling:** Important for the paper's secondary finding about convergence. 
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Transaction Density at REP/Non-REP Boundaries"
**Page:** 19
- **Formatting:** Standard McCrary-style histogram.
- **Clarity:** The mass point at $X \approx 50$ is very clear.
- **Storytelling:** Honest reporting of the sorting/mechanical density issues.
- **Labeling:** The note includes the T-statistic and p-value.
- **Recommendation:** **MOVE TO APPENDIX**
  - While important for transparency, the density test confirms a violation of RDD assumptions that the paper already acknowledges. In a 40-page QJE paper, this is usually an appendix figure unless the sorting itself is the primary object of study.

### Figure 4: "Covariate Smoothness at REP/Non-REP Boundaries"
**Page:** 20
- **Formatting:** Two-panel figure. 
- **Clarity:** Shows the "kink" in apartment share clearly.
- **Storytelling:** Reinforces the sorting narrative.
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - These two panels would be better presented as "Panel A: Surface Area" and "Panel B: Apartment Share" with a single shared legend if applicable.
  - Move to Appendix to save main-text space for the mechanism results.

### Figure 5: "Bandwidth Sensitivity of Boundary Estimates"
**Page:** 21
- **Formatting:** Standard sensitivity plot.
- **Clarity:** Shows the estimate is stable.
- **Storytelling:** Essential robustness for RDD.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**
  - Stability across bandwidths is a "check the box" requirement. It rarely needs to be in the main text of a top-tier journal if the baseline result is well-established.

### Figure 6: "REP Boundary Gap by Private School Availability"
**Page:** 23
- **Formatting:** Excellent use of color to show the "escape valve" mechanism.
- **Clarity:** The contrast between the red (low density) and blue (high density) slopes is the most compelling visual in the paper.
- **Storytelling:** This is the most "academic" contribution of the paper. It moves beyond "is there a gap?" to "why does the gap exist?".
- **Labeling:** Very good.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Table 7: "Placebo Tests at Shifted Boundary Locations"
**Page:** 32
- **Recommendation:** **KEEP AS-IS**

### Table 8: "Year-by-Year RDD Estimates at REP/Non-REP Boundaries"
**Page:** 33
- **Storytelling:** Redundant with Figure 2.
- **Recommendation:** **KEEP AS-IS** (Appendix tables often provide the raw numbers for figures in the main text).

---

## Overall Assessment

- **Exhibit count:** 2 main tables, 6 main figures, 2 appendix tables, 0 appendix figures.
- **General quality:** High. The figures are modern (ggplot2-style) and the tables follow standard econometric reporting.
- **Strongest exhibits:** Figure 1 (Visual Evidence) and Figure 6 (Private School Mechanism).
- **Weakest exhibits:** Figure 5 (Redundant for main text) and Figure 3 (Necessary but belongs in appendix).
- **Missing exhibits:** 
  1. **Map of Study Area:** A QJE-style paper needs a map showing the geographic distribution of REP vs. non-REP schools, perhaps zoomed in on one Parisian boundary to show the "Voronoi-like" construction of the running variable.
  2. **Regression Table for Private School Mechanism:** While Figure 6 is great, a table showing the interaction term ($REP\_side \times Private\_Density$) with various controls would provide the formal statistical proof.

### Top 3 Improvements:
1. **Consolidate Robustness:** Move Figure 3 (Density), Figure 4 (Covariates), and Figure 5 (Bandwidth) to the Appendix. This streamlines the main text to focus on Figure 1 (The Fact), Table 2 (The Sorting Explanation), and Figure 6 (The Mechanism).
2. **Rescale Distance Coefficients:** In Table 2, the coefficients for distance are currently too small ($10^{-5}$). Rescaling distance to kilometers or hectometers will make these key gradients readable.
3. **Add a Map:** Visualize the "Implicit Boundary" construction. Readers need to see the spatial nature of the Voronoi-style design to trust the running variable.