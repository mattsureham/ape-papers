# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-04-07T20:49:10.229172
**Route:** Direct Google API + PDF
**Tokens:** 17357 in / 1897 out
**Response SHA256:** 8e200f4d5a88081c

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Building Permits by Treatment Status"
**Page:** 8
- **Formatting:** Clean and professional. Use of parentheses for standard deviations is standard. Horizontal rules follow the "booktabs" style appropriate for top journals.
- **Clarity:** Good. The Pre/Post and Treated/Control split is logical. 
- **Storytelling:** Essential. It immediately establishes the massive level differences between groups, which justifies the use of Fixed Effects and the focus on trends.
- **Labeling:** Clear. Units (quarterly permits) are mentioned in the notes but would be better in the stub or a sub-header.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Effect of the Renovation Cap on Building Permits"
**Page:** 11
- **Formatting:** Good, but the variable names in the first row (`total_permits`, `log_permits`) are "code-speak." These should be replaced with clean, formatted labels (e.g., "Total Permits (Levels)").
- **Clarity:** The four columns provide a comprehensive look at levels vs. logs for two outcomes.
- **Storytelling:** This is the "money table." It confirms the headline result.
- **Labeling:** Significance stars are used but not defined in the table note (though standard, they should be explicit). "muni_id" and "time_id" should be renamed "Municipality FE" and "Quarter FE".
- **Recommendation:** **REVISE**
  - Replace snake_case variable names with professional labels.
  - Define significance stars in the notes.
  - Change "muni_id" and "time_id" to "Municipality FE" and "Quarter FE".

### Figure 1: "Event Study: Building Permits (Restricted Pre-Period, 2015+)"
**Page:** 12
- **Formatting:** Modern ggplot2 style. The 95% CI shading is professional. 
- **Clarity:** Very high. The "pipeline effect" (the delay in effect) is visually obvious. 
- **Storytelling:** The most important figure in the paper. It validates the parallel trends and shows the timing of the response.
- **Labeling:** Axis labels are clear. The red dashed line for the reform is helpful. 
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Raw Building Permit Trends: Treated vs. Control Municipalities"
**Page:** 13
- **Formatting:** A bit cluttered due to the high-frequency volatility of the raw data.
- **Clarity:** The huge gap in levels makes it hard to see if the trends are truly parallel in the pre-period.
- **Storytelling:** This figure is meant to show "raw" data, but because of the level difference, it's less effective than Figure 1. 
- **Recommendation:** **MOVE TO APPENDIX** (The event study and log regressions handle the identification argument more cleanly).

### Figure 3: "Multifamily Building Permit Trends: Treated vs. Control"
**Page:** 14
- **Formatting:** Same as Figure 2.
- **Clarity:** High volatility makes the "raw" trend hard to parse.
- **Storytelling:** Redundant if Table 2 and the text already describe the multifamily concentration.
- **Recommendation:** **MOVE TO APPENDIX**

### Figure 4: "Dwelling Stock Evolution by Tenancy Type"
**Page:** 15
- **Formatting:** Multi-line plot with different colors/styles. 
- **Clarity:** A bit busy. Having four lines (Control/Treated x Owner/Rental) makes the 2019-indexed comparison difficult to read at a glance.
- **Storytelling:** This is a secondary mechanism check. 
- **Labeling:** The legend is clear, but the y-axis (Index 2019=100) is slightly cramped.
- **Recommendation:** **REVISE**
  - Split into two panels: Panel A (Rental Stock), Panel B (Owner-Occupied Stock). This would make the Treated vs. Control divergence much easier to see.

### Table 3: "Robustness Checks"
**Page:** 18
- **Formatting:** Consistent with Table 2.
- **Clarity:** Good. It logically groups different "stress tests" of the main model.
- **Storytelling:** Vital for top journals to show that results aren't driven by specific window choices or COVID.
- **Labeling:** Again, snake_case labels (`total_permits`) should be cleaned up.
- **Recommendation:** **REVISE**
  - Clean up variable labels and FE labels to match Table 2 revisions.

### Table 4: "Placebo Tests"
**Page:** 18
- **Formatting:** Professional.
- **Clarity:** Mixing a 2018 placebo (permits) with dwelling stock results in one table is a bit confusing. 
- **Storytelling:** The 2018 placebo is a "dead end" result (which is good), while the stock results are "mechanism" results.
- **Recommendation:** **REVISE**
  - Move the Dwelling Stock results (Cols 2-3) to a dedicated "Mechanism" table. Keep Column 1 as a standalone Placebo table or merge it into the Robustness table.

### Figure 5: "Event Study: Full Panel (2006–2025)"
**Page:** 19
- **Formatting:** Good.
- **Clarity:** Shows the pre-2015 divergence clearly.
- **Storytelling:** This justifies why the author uses the "Restricted" window in Figure 1.
- **Recommendation:** **MOVE TO APPENDIX** (The main text should focus on the "clean" 2015+ identification).

### Figure 6: "Event Study: Multifamily Building Permits"
**Page:** 20
- **Formatting:** Good.
- **Clarity:** The CI is much wider here, which is honest but shows the data is noisier for this subcategory.
- **Storytelling:** Strong support for the "renovation" channel.
- **Recommendation:** **PROMOTE TO MAIN TEXT** (Replace Figure 2 or 3 with this).

### Figure 7: "Distribution of Building Permits: Pre vs. Post Reform"
**Page:** 21
- **Formatting:** Excellent ridge/density plot. 
- **Clarity:** Very clear shift in the "Treated" distribution.
- **Storytelling:** Excellent way to show the effect isn't just driven by Copenhagen (outliers).
- **Recommendation:** **KEEP AS-IS**

## Appendix Exhibits

### Table 5: "Standardized Effect Sizes"
**Page:** 31
- **Formatting:** This looks more like a "summary of results" than a standard regression table.
- **Clarity:** High. It translates the coefficients into a standardized language.
- **Storytelling:** Helpful for comparing the "Large Cities" vs. others.
- **Labeling:** Very detailed notes.
- **Recommendation:** **PROMOTE TO MAIN TEXT** (Perhaps as a "Heterogeneity" table, Panel B is particularly strong).

---

## Overall Assessment

- **Exhibit count:** 4 Main Tables, 7 Main Figures, 1 Appendix Table, 0 Appendix Figures.
- **General quality:** The figures are visually modern and high-quality (ggplot2 style). The tables are structurally sound but suffer from "code-speak" labeling (snake_case) which looks amateurish for an AER/QJE submission.
- **Strongest exhibits:** Figure 1 (Event Study) and Figure 7 (Distribution shift).
- **Weakest exhibits:** Figure 2 and Figure 3 (raw trends are too messy/noisy to be in the main text).
- **Missing exhibits:** A map of Denmark showing treated vs. opt-out municipalities would be extremely helpful for readers unfamiliar with Danish geography.

**Top 3 improvements:**
1. **Label Cleanup:** Remove all raw variable names (e.g., `total_permits`, `muni_id`) and replace with LaTeX-formatted professional names.
2. **Declutter Main Text Figures:** Move the "Raw Trend" figures (Fig 2 & 3) to the appendix. They add noise rather than clarity. Replace them with the Multifamily Event Study (Fig 6).
3. **Add a Map:** Include a "Figure 0" or Figure 1 showing the 80 treated and 18 control municipalities. This is standard for papers using regional policy variation.