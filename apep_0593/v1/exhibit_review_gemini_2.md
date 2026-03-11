# Exhibit Review — Gemini 3 Flash (Round 2)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-11T10:40:53.239457
**Route:** Direct Google API + PDF
**Tokens:** 19957 in / 2067 out
**Response SHA256:** 682ac0c0f6a824d6

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Figure 1: "Classification of NUTS2 Regions by Border Type"
**Page:** 8
- **Formatting:** Clean, professional map. The legend is well-placed. The projection of Europe is standard for Eurostat data.
- **Clarity:** Excellent. The color coding clearly distinguishes between the treated group (Internal), the placebo group (External), and the control group (Interior).
- **Storytelling:** Essential. It visualizes the spatial identification strategy, which is the core of the paper.
- **Labeling:** Clear. Legend identifies all categories, and notes explain the exclusions (islands).
- **Recommendation:** **KEEP AS-IS**

### Table 1: "Summary Statistics: Border vs. Interior NUTS2 Regions, 2012–2019"
**Page:** 9
- **Formatting:** Needs decimal alignment. The means and standard deviations have varying numbers of digits after the decimal point (e.g., `.5` vs `.4`).
- **Clarity:** Good. The choice of variables (Nights, Pop, GDP) provides a complete picture of regional scale.
- **Storytelling:** Highlights the "Capital City" effect (Interior regions being larger/richer), justifying the need for the country-by-year fixed effects used later.
- **Labeling:** Statistic names are clear. 
- **Recommendation:** **REVISE**
  - Use `dcolumn` or `siunitx` in LaTeX to align numbers by the decimal point.
  - Consistent decimal places (e.g., round all large counts to nearest integer or one decimal place).
  - Add a "Difference" column with a t-test for balance to make the comparison more rigorous for a top journal.

### Table 2: "Effect of Roaming Abolition on Foreign Tourist Nights"
**Page:** 13
- **Formatting:** Professional AER-style layout. Good use of horizontal rules. Numbers are well-spaced.
- **Clarity:** The header "Log Domestic Ni" is cut off (OCR/Formatting error). Column (5) needs its title fully visible.
- **Storytelling:** This is the "money table." It presents the baseline, the preferred specification (Col 3), and the placebo (Col 5) in one logical flow.
- **Labeling:** "Signif. Codes" are standard. Fixed-effects rows are clear.
- **Recommendation:** **REVISE**
  - Fix the column header for Column (5) to "Log Domestic Nights (Placebo)".
  - Ensure "Within R²" is consistently formatted (currently scientific notation in some tables and decimals in others).

### Figure 2: "Event Study: Effect of RLAH on Foreign Tourist Nights in Border Regions"
**Page:** 15
- **Formatting:** Standard event study plot. The shaded 95% CI is clean.
- **Clarity:** The large "dip" at $t=-3$ is visually distracting but explained by the wide CI. The red dotted line for treatment is standard and helpful.
- **Storytelling:** Crucial for validating the parallel trends assumption. It shows a very flat pre-trend (except for the noisy $t=-3$).
- **Labeling:** Axis labels are perfect. Note includes the joint F-test result, which is excellent practice.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Raw Trends: Foreign Tourist Nights in Border vs. Interior Regions"
**Page:** 16
- **Formatting:** Clean line chart.
- **Clarity:** Very high. The indexing to 100 at $t=2016$ makes the comparison intuitive.
- **Storytelling:** Provides "transparent visual evidence" before the regression machinery. It shows both groups growing at nearly identical rates.
- **Labeling:** Clear legend and axis.
- **Recommendation:** **KEEP AS-IS** (Though could be combined with Figure 4 into a two-panel figure).

### Table 3: "Border Comparison and Matched Sample"
**Page:** 17
- **Formatting:** Professional.
- **Clarity:** Clear. It effectively shows that matching (Col 3) doesn't change the point estimate.
- **Storytelling:** Good robustness. However, it feels slightly redundant with Table 2.
- **Recommendation:** **MOVE TO APPENDIX**
  - The main text is already heavy on "null" results. The matching result is a secondary robustness check that doesn't change the narrative.

### Figure 4: "Placebo: Domestic Tourist Nights in Border vs. Interior Regions"
**Page:** 18
- **Formatting:** Consistent with Figure 3.
- **Clarity:** High.
- **Storytelling:** Proves that the "Border" effect isn't just a general tourism trend in those regions.
- **Recommendation:** **REVISE**
  - **Consolidate:** Combine Figure 3 and Figure 4 into a single Figure with Panel A (Foreign Nights) and Panel B (Domestic Nights). This allows the reader to see the parallel trends for both outcomes at once.

### Figure 5: "Leave-One-Country-Out Robustness"
**Page:** 23
- **Formatting:** "Caterpillar" plot is a bit cluttered with 27 countries.
- **Clarity:** Hard to read individual country names at this scale.
- **Storytelling:** Important to show no single country (like a small Luxembourg or a tourism giant like Italy) drives the null.
- **Recommendation:** **MOVE TO APPENDIX**
  - This is a standard but "low-information-density" plot. Summarizing it in the text ("Coefficients range from X to Y") is sufficient for the main body.

---

## Appendix Exhibits

### Figure 6: "Event Study: Continuous Treatment (Pre-Treatment Foreign Share)"
**Page:** 32
- **Formatting:** Consistent with Figure 2.
- **Clarity:** High.
- **Storytelling:** Supports the dose-response argument.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Leave-One-Country-Out Robustness"
**Page:** 33
- **Formatting:** This is a raw list of numbers.
- **Clarity:** Low. It’s a wall of text.
- **Storytelling:** Redundant with Figure 5.
- **Recommendation:** **REMOVE** (or keep only if Figure 5 is removed). Having both the plot and the full table is excessive for most journals.

### Table 5: "Placebo Test: Fake Treatment at 2015"
**Page:** 34
- **Formatting:** Good.
- **Clarity:** Clear.
- **Storytelling:** Strong evidence against pre-existing trends.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Heterogeneity Analysis: Border x Post by Subgroup"
**Page:** 35
- **Formatting:** Excellent use of grouping.
- **Clarity:** Very high. Shows the consistency of the null across three different dimensions of heterogeneity.
- **Storytelling:** This is a very strong table. It anticipates the reader's question: "Does it work in the North? Does it work for high-tourism areas?"
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - This table significantly strengthens the "Null" argument by showing it isn't an artifact of aggregation.

### Table 7: "Standardized Effect Sizes"
**Page:** 36
- **Formatting:** Clean.
- **Clarity:** High.
- **Storytelling:** This is unusual for Econ but very helpful for "interpreting a null." It proves the effect is not just insignificant, but "Null" in magnitude.
- **Recommendation:** **KEEP AS-IS** (in Appendix)

---

## Overall Assessment

- **Exhibit count:** 3 main tables (after moves), 3 main figures (after consolidation), 4 appendix tables, 2 appendix figures.
- **General quality:** High. The paper follows the "modern DiD" template perfectly (Map $\rightarrow$ Raw Trends $\rightarrow$ Event Study $\rightarrow$ Regressions $\rightarrow$ Heterogeneity).
- **Strongest exhibits:** Figure 1 (Map) and Table 6 (Heterogeneity).
- **Weakest exhibits:** Table 4 (Wall of numbers) and Figure 5 (Cluttered labels).
- **Missing exhibits:** A **"Mechanism" Figure** or Table showing the 490% data traffic surge. The paper mentions this number repeatedly as the "first stage," but we never see the plot. A figure showing the discontinuity in data traffic in June 2017 would be the "First Stage" plot that makes the "Reduced Form" null even more striking.

### Top 3 Improvements:
1.  **Add the "First Stage" Figure:** Create a figure showing EU-wide mobile data roaming traffic (2014–2019) to visually document the 490% surge mentioned in the text. This sets the stage for the tourism null.
2.  **Consolidate and Clean:** Merge Figures 3 and 4 into a two-panel figure. Move Figure 5 and Table 3 to the Appendix to tighten the main text.
3.  **Promote Table 6:** Bring the heterogeneity analysis into the main text. In a "Null Result" paper, proving the result holds across all subgroups is the most important task to satisfy skeptical reviewers.