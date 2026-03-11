# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-11T11:44:43.464464
**Route:** Direct Google API + PDF
**Tokens:** 19957 in / 1833 out
**Response SHA256:** 48f05004af50cf17

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics"
**Page:** 11
- **Formatting:** Clean and professional. Use of panels (A and B) effectively separates the two distinct datasets.
- **Clarity:** High. The table clearly shows the unit of observation and the distribution of the key variables.
- **Storytelling:** Essential. It establishes the massive jump in mean PMS prices (209 to 547) mentioned in the text and the wide variation in distances.
- **Labeling:** Good. Includes units (Naira, km). Note: The currency symbol (=N) is slightly non-standard; ensure it matches journal LaTeX requirements (usually `\text naira`).
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Petrol Price Pass-Through: The Effect of Distance from Import Terminals"
**Page:** 15
- **Formatting:** Standard three-line table format. Decimal alignment is good.
- **Clarity:** The transition from OLS to FE is logical. However, "adm1_name" and "mkt_name" are variable names; replace with "State" and "Market" for a more polished look.
- **Storytelling:** This is the baseline result. It correctly shows that while the aggregate jump is huge (Column 1), the distance gradient is subtle and potentially attenuated in the full-sample FE specification.
- **Labeling:** Significance stars are defined. Standard errors are in parentheses. Note: "dist_100km" in the variable row should be renamed "Distance (100km)" to match the interaction label below it.
- **Recommendation:** **REVISE**
  - Rename variable labels "mkt_name", "adm1_name", and "dist_100km" to "Market", "State", and "Distance (100km)".

### Figure 1: "Event Study: Distance Gradient in Petrol Prices"
**Page:** 16
- **Formatting:** Journal-quality. Clean gridlines and appropriate use of a dashed vertical line for the treatment date.
- **Clarity:** Excellent. The key message (zero pre-trend, sharp jump, gradual decay) is visible in seconds.
- **Storytelling:** Crucial for the identification strategy. It justifies the bandwidth analysis by showing the effect is transitory.
- **Labeling:** Y-axis label is descriptive. X-axis clearly marks the reform month.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Market Locations and Distance to Petroleum Import Terminals"
**Page:** 17
- **Formatting:** The coordinate plane approach is a good substitute for a full map if GIS boundaries are messy.
- **Clarity:** The color gradient effectively shows the treatment intensity.
- **Storytelling:** Helps the reader visualize the "treatment"—remoteness from the coast.
- **Labeling:** Legend is clear. 
- **Recommendation:** **REVISE**
  - Consider adding a faint outline of Nigeria's national border or regional divisions to provide better geographic context than just a grid of Longitude/Latitude.

### Figure 3: "PMS Price Trajectories by Distance Tercile"
**Page:** 18
- **Formatting:** Professional. Use of shaded confidence intervals/standard error bands is good.
- **Clarity:** Very high. The "fan" opening after April 2023 is the "smoking gun" of the paper.
- **Storytelling:** This is arguably the most important figure for a general interest reader. It shows the raw data pattern that the regressions later formalize.
- **Labeling:** The red vertical label "Subsidy Removed" is very helpful.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Food Price Pass-Through by Transport Intensity and Commodity Group"
**Page:** 19
- **Formatting:** Good. Logical grouping of columns.
- **Clarity:** Clear contrast between transport-intensive (cereal) and placebo (protein).
- **Storytelling:** This is the "Plates" part of the paper. It confirms the mechanism.
- **Labeling:** Comprehensive.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Food Price Distance Gradient by Commodity Group"
**Page:** 20
- **Formatting:** Clean coefficient plot. 
- **Clarity:** High. 
- **Storytelling:** Effectively summarizes Table 3. It makes the heterogeneity immediately apparent.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Distance and Post-Reform Petrol Price Changes"
**Page:** 21
- **Formatting:** Good use of color-coding by state.
- **Clarity:** A bit cluttered. The 14-color legend is difficult to map to individual dots.
- **Storytelling:** Shows the cross-sectional correlation. 
- **Recommendation:** **MOVE TO APPENDIX**
  - This is a bivariate relationship that is better summarized by Figure 3 or Figure 1. It adds less marginal value to the main text than the other exhibits.

### Table 4: "Robustness: Bandwidth Sensitivity"
**Page:** 22
- **Formatting:** Clean.
- **Clarity:** Simple and effective.
- **Storytelling:** Vital for explaining why the Table 2 full-sample result is "weaker" than the headline 12-month result.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

## Appendix Exhibits

### Figure 6: "Leave-One-Out State Analysis"
**Page:** 23
- **Formatting:** Standard coefficient plot.
- **Clarity:** Clear.
- **Storytelling:** Demonstrates that the result isn't driven by any single state (e.g., Borno).
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

### Figure 7: "Randomization Inference: Permutation Distribution"
**Page:** 24
- **Formatting:** High-quality histogram.
- **Clarity:** The placement of the "Actual" line makes the p-value result intuitive.
- **Storytelling:** Supports the inference section.
- **Labeling:** Red text for the actual estimate is a good touch.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Standardized Effect Sizes"
**Page:** 36
- **Formatting:** Clear.
- **Clarity:** Good for comparing magnitudes across different outcomes (petrol vs food).
- **Storytelling:** Helpful for reviewers to judge "economic significance" vs just "statistical significance."
- **Labeling:** Comprehensive notes.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 4 Main Tables, 5 Main Figures, 1 Appendix Table, 2 Appendix Figures.
- **General quality:** Extremely high. The exhibits follow the "self-contained" principle (notes are detailed enough to understand the table without the text). The visual style is consistent with top-tier journals like the AEJs or AER.
- **Strongest exhibits:** Figure 3 (Trajectories) and Figure 1 (Event Study).
- **Weakest exhibits:** Figure 5 (Cluttered scatter) and Table 2 (Variable names need cleaning).
- **Missing exhibits:** 
    - **Map of Food Production:** Since the paper argues that cereals are produced in the North and trucked South, a map showing "Cereal Surplus Areas" vs "Deficit Areas" would strengthen the mechanism argument.
    - **Diesel vs Petrol Comparison Table:** The text mentions Diesel as a benchmark. A table showing the Diesel gradient side-by-side with the Post-Reform Petrol gradient would be a powerful "sanity check."

### Top 3 improvements:
1.  **Clean up Table 2 and Table 3 labels:** Remove underscores and computer-variable names (e.g., `mkt_name`) and replace with "Market" or "State."
2.  **Streamline Main Text Figures:** Move Figure 5 to the appendix to keep the main text focused on the most "active" storytelling exhibits (Figures 1 and 3).
3.  **Enhance Figure 2:** Add a geographic outline of Nigeria. A grid of dots on a coordinate plane feels slightly "unanchored" for a paper where geography is the central theme.