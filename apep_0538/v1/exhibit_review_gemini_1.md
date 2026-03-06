# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-06T13:01:29.224759
**Route:** Direct Google API + PDF
**Tokens:** 17877 in / 2127 out
**Response SHA256:** c87096d72984a1ad

---

This review evaluates the visual exhibits of the paper "Do Low-Emission Zones Capitalize into Housing Prices?" against the standards of top-tier economics journals (AER, QJE, etc.).

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "ZFE Adoption by City (DVF-Covered Regions)"
**Page:** 6
- **Formatting:** Professional and clean. Uses standard booktabs-style horizontal lines.
- **Clarity:** Excellent. It provides a clear roadmap of the staggered treatment essential for the DiD design.
- **Storytelling:** Vital for establishing the "staggered" nature of the rollout.
- **Labeling:** Clear. The note explaining the exclusion of Strasbourg is important for transparency.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Summary Statistics: Residential Transactions within 2km of ZFE Boundaries"
**Page:** 9
- **Formatting:** Standard. Number alignment is good.
- **Clarity:** The table is a bit dense. The "Inside x Post" and "Control group" rows are actually a breakdown of the sample, but the layout doesn't make the hierarchy immediately clear.
- **Storytelling:** Crucial. It hints at the paper's core argument by showing the massive raw price gap (6839 vs 5701) which motivates the concern about selection bias.
- **Labeling:** Units are present. 
- **Recommendation:** **REVISE**
  - Add a sub-header or indentation to distinguish the "Full Sample" from the "Inside/Outside" and "Inside x Post/Control" subgroups.
  - Add a column for the difference in means (Inside vs. Outside) with t-stats to formally show the lack of balance.

### Table 3: "Main Results: Effect of ZFE on Residential Housing Prices"
**Page:** 12
- **Formatting:** Journal-ready. Standard error parentheses and significance stars are correct.
- **Clarity:** Very high. The progression of controls (Basic $\rightarrow$ Hedonic $\rightarrow$ Commune FE) tells the story of the coefficient collapsing.
- **Storytelling:** This is the "money table." It sets up the straw man (TWFE bias) that the rest of the paper deconstructs.
- **Labeling:** Good. "Inside ZFE $\times$ Post" is a standard variable name.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Event Study: Inside ZFE × Quarter Relative to Adoption"
**Page:** 13
- **Formatting:** Clean ggplot2 style. Gridlines are subtle.
- **Clarity:** The message is instant: the pre-trend is massive and significant.
- **Storytelling:** Perfectly placed to immediately follow the "naive" results in Table 3.
- **Labeling:** The y-axis "Effect on Log(Price/m2)" is clear. The red dashed line at $t=0$ is essential.
- **Recommendation:** **REVISE**
  - The shaded 95% CI is a bit "heavy." Consider using thinner lines for the CI or a more transparent fill.
  - Point out the $n=-1$ reference period more explicitly in the legend or a label.

### Figure 2: "Callaway–Sant’Anna Dynamic Treatment Effects"
**Page:** 15
- **Formatting:** Consistent with Figure 1.
- **Clarity:** Excellent contrast to Figure 1. The flat pre-trend is the "hero" of this figure.
- **Storytelling:** Confirms that the CS-DiD estimator solves the problem identified in Figure 1.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Distance Gradient: Price Effects Around ZFE Boundaries"
**Page:** 16
- **Formatting:** Good use of color (Red/Blue) to distinguish Inside/Outside.
- **Clarity:** Very high. The monotonic increase across the boundary is easy to see.
- **Storytelling:** Supports the "Urban-Suburban Divide" argument by showing the effect exists even far from the boundary.
- **Labeling:** "ZFE Boundary" label is well-placed.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "First Stage: ZFE Adoption and Air Quality"
**Page:** 17
- **Formatting:** Standard.
- **Clarity:** Clear, though $N=540$ is a small sample compared to the millions of transactions earlier.
- **Storytelling:** Essential. It provides the "mechanism" (or lack thereof). If air quality didn't improve much, prices shouldn't move much.
- **Labeling:** $\mu g/m^3$ units included.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Robustness Checks"
**Page:** 18
- **Formatting:** A bit non-standard for a main table; it looks like a summary of other regressions.
- **Clarity:** Good. It consolidates diverse tests (Bandwidth, Donut, Placebo) into one view.
- **Storytelling:** Strong. Shows the bias is robust to bandwidth choice.
- **Labeling:** Randomization $p$-value at the bottom is a nice touch.
- **Recommendation:** **REVISE**
  - Consider moving the commercial placebo and donut results to their own small tables or panels. This table feels like a "results list" rather than a formal regression table.

### Figure 4: "Randomization Inference Distribution"
**Page:** 19
- **Formatting:** Good.
- **Clarity:** The red line "Actual estimate" is far to the right, showing the TWFE result is an outlier.
- **Storytelling:** Provides the final "nail in the coffin" for the TWFE result.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "TWFE Effect by Apartment Size Quintile"
**Page:** 20
- **Formatting:** Consistent.
- **Clarity:** Good.
- **Storytelling:** Important for the "Green Gentrification" debate. Shows the "effect" is largest for small apartments (the most urban ones).
- **Labeling:** X-axis labels are clear.
- **Recommendation:** **MOVE TO APPENDIX**
  - This is a secondary heterogeneity result. The main paper is already exhibit-heavy.

### Figure 6: "TWFE Effect by City"
**Page:** 21
- **Formatting:** Horizontal dot plot is the correct choice here.
- **Clarity:** Excellent. Shows the massive variance across cities.
- **Storytelling:** Supports the idea that the "effect" is really just city-specific urban trends.
- **Labeling:** Including $N$ next to each city name is very helpful.
- **Recommendation:** **KEEP AS-IS** (Or consider Panel-ing with the first stage AQ results).

---

## Appendix Exhibits

### Figure 7: "Robustness to Boundary Bandwidth"
**Page:** 31
- **Formatting:** Redundant with Table 5.
- **Storytelling:** Visualizes the monotonic increase mentioned in the text.
- **Recommendation:** **REVISE**
  - This is more effective than the "Bandwidth" rows in Table 5. I recommend removing the bandwidth rows from Table 5 and making this Figure 7 the primary way you show bandwidth sensitivity (keeping it in the appendix).

### Figure 8: "NO2 Trends Around ZFE Adoption"
**Page:** 32
- **Formatting:** The colors are a bit hard to distinguish (spaghetti plot).
- **Clarity:** Messy. The vertical lines for different cities make it hard to track which line corresponds to which adoption.
- **Storytelling:** Intended to show no "break" in the raw AQ data at adoption.
- **Recommendation:** **REVISE**
  - Instead of a spaghetti plot of raw levels, use a **single-panel AQ event study figure** (similar to Figure 2) using the CAMS data. It would be much more professional and easier to read than raw time series.

---

## Overall Assessment

- **Exhibit count:** 4 main tables, 6 main figures, 0 appendix tables, 2 appendix figures.
- **General quality:** High. The paper uses modern "Diagnostic" viz (event studies, RI distributions, gradients) effectively.
- **Strongest exhibits:** Figure 1 (Pre-trend reveal), Figure 2 (The CS-DiD solution), Figure 3 (Distance gradient).
- **Weakest exhibits:** Figure 8 (Spaghetti plot), Table 5 (Too many disparate things in one list).
- **Missing exhibits:** A **Map Figure** showing the nine cities and a zoom-in on one city's ZFE boundary (e.g., Paris or Lyon) with transaction dots. Top journals (especially in Urban/Regional) almost always expect a geographic visualization of the treatment.

### Top 3 Improvements:
1.  **Add a Map Figure:** Create a "Figure 1" that shows the ZFE polygons across France and a "Panel B" zoom-in of a specific boundary. This grounds the "Urban-Suburban" argument visually.
2.  **Clean up the Robustness/Placebo reporting:** Split Table 5. Keep the Bandwidth checks in a figure (Fig 7) and create a "Table 5: Alternative Specifications" that looks like a standard regression table for the Donut and Commercial Placebo tests.
3.  **Upgrade the AQ Appendix:** Replace the Figure 8 spaghetti plot with an Event Study plot for Air Quality. This would mirror the price results and be more persuasive.