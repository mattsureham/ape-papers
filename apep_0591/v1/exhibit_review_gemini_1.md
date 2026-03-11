# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-11T10:18:46.993996
**Route:** Direct Google API + PDF
**Tokens:** 18917 in / 1903 out
**Response SHA256:** 787adc2ace72864a

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 2: "Summary Statistics"
**Page:** 9
- **Formatting:** Clean but lacks standard top journal horizontal rules (should use `booktabs` style: heavy top/bottom rules, thin mid-rule). Number of observations (N) varies; should clarify why in notes. 
- **Clarity:** Good. Variables are clearly named with units.
- **Storytelling:** Essential. It establishes the scale of the "Tertiary share" (37%) vs. the "Erasmus outflow rate" (3.5 per 1k).
- **Labeling:** There are two titles ("Table 1" and "Table 2") printed above it; delete "Table 1".
- **Recommendation:** **REVISE**
  - Delete the redundant "Table 1" label.
  - Add a note explaining the unit of observation (NUTS2 region-year).
  - Use `booktabs` formatting (remove vertical lines if any, though none are visible here).

### Table 3: "First Stage: Bartik Instrument and Erasmus Outflows"
**Page:** 13
- **Formatting:** Standard "stargazer" output. Decimal alignment is missing.
- **Clarity:** Clear distinction between Growth and Level models.
- **Storytelling:** Essential for a shift-share paper. Proves the instrument isn't weak (F=1,376).
- **Labeling:** "Signif. Codes" should be moved to a table note. "nuts2" and "year" should be capitalized.
- **Recommendation:** **REVISE**
  - Decimal-align the coefficients and standard errors.
  - Capitalize "NUTS2" and "Year" in the Fixed-effects section.
  - Report the Kleibergen-Paap F-statistic explicitly in the fit statistics.

### Figure 1: "First-Stage Binscatter: Bartik Instrument and Erasmus Outflow Rate"
**Page:** 13
- **Formatting:** Professional ggplot-style. Gridlines are a bit heavy for top journals.
- **Clarity:** Excellent. Shows a tight linear relationship.
- **Storytelling:** Visually confirms Table 3.
- **Labeling:** Good. Axes include "residualized" which is crucial.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Main Results: Effect of Erasmus Outflows on Regional Human Capital"
**Page:** 15
- **Formatting:** Standard. 
- **Clarity:** Mixing different outcome units (percentage points for Col 1-3 vs. thousands for Col 4-5) makes comparison difficult.
- **Storytelling:** This is the "money" table. The contrast between OLS (null) and 2SLS (negative) is the core finding.
- **Labeling:** Footnote is comprehensive.
- **Recommendation:** **REVISE**
  - Add the mean of the dependent variable to the bottom of the table to help the reader interpret the magnitude of the -0.389 coefficient.
  - Separate Labor Market outcomes (Col 4-5) into a "Panel B" or a different table to avoid mixing units in the same header row.

### Figure 2: "Reduced Form: Predicted Outflows and Tertiary Education Share"
**Page:** 15
- **Formatting:** Consistent with Figure 1. 
- **Clarity:** The confidence interval is wide, reflecting the p=0.005 in the text.
- **Storytelling:** High importance for shift-share transparency.
- **Labeling:** Y-axis label "(residualized, pp)" is clear.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Placebo Test: Erasmus-Affected vs. Broader Cohort"
**Page:** 17
- **Formatting:** Consistent with Table 4.
- **Clarity:** High. The contrast between the young and old cohort coefficients is stark.
- **Storytelling:** Critical for the "Identification" story. 
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Placebo: Effect on Young (25–34) vs. Older (25–64) Tertiary Share"
**Page:** 17
- **Formatting:** Clean coefficient plot.
- **Clarity:** Excellent visual summary of the paper's strongest identification check.
- **Storytelling:** Redundant if Table 5 is present, but for QJE/AER, having a visual "Placebo" is standard.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Heterogeneity: Effects by Regional Characteristics"
**Page:** 18
- **Formatting:** "Peripheral" and "Core" labels should be in a header row above the columns.
- **Clarity:** Logical grouping.
- **Storytelling:** Supports the "Divergence" argument.
- **Recommendation:** **REVISE**
  - Group columns 1-2 under a "GDP" header and 3-4 under a "Net Flows" header.

### Figure 4: "Heterogeneity: 2SLS Estimates by Regional GDP Level"
**Page:** 19
- **Formatting:** Consistent.
- **Clarity:** Good.
- **Storytelling:** A bit redundant with Table 6.
- **Recommendation:** **MOVE TO APPENDIX** (Keep the table in the main text; the plot doesn't add new info).

---

## Appendix Exhibits

### Figure 5: "Randomization Inference: Distribution of Permuted Coefficients"
**Page:** 21
- **Recommendation:** **KEEP AS-IS** (Standard requirement for BHJ (2022) style papers).

### Figure 6: "Leave-One-Country-Out Stability of the Main Estimate"
**Page:** 22
- **Clarity:** Very cluttered. 30+ countries on the Y-axis.
- **Recommendation:** **REVISE**
  - Sort the Y-axis by the point estimate (not alphabetical) to show which countries are most influential.

### Table 7: "Robustness: Alternative Specifications"
**Page:** 31
- **Note:** Column (4) is mentioned in the text (pre-trend) but is missing from the table in the screenshot.
- **Recommendation:** **REVISE**
  - Ensure Column 4 (Pre-trend test) is actually printed in the table.

### Table 8: "Cross-Sectional Long-Difference Specification"
**Page:** 32
- **Recommendation:** **KEEP AS-IS** (Correctly placed in appendix as the first stage is weak).

### Figure 7: "Net Erasmus+ Student Outflows by NUTS2 Region, 2014–2019"
**Page:** 33
- **Clarity:** Maps are essential for regional papers.
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - This map should be in Section 2 or 3. It immediately visualizes the "Core-Periphery" structure the paper discusses.

### Table 9: "Standardized Effect Sizes"
**Page:** 34
- **Recommendation:** **REVISE**
  - This is helpful but look-and-feel is "raw data." Format it as a professional table (remove "Table 3, Col 2" internal references; use descriptive labels).

---

## Overall Assessment

- **Exhibit count:** 5 main tables, 4 main figures, 4 appendix tables, 3 appendix figures.
- **General quality:** High. The paper follows modern IV/Shift-share visualization standards (binscatters, placebo plots, RI distributions).
- **Strongest exhibits:** Figure 3 (Placebo plot) and Figure 1 (First stage).
- **Weakest exhibits:** Table 9 (formatting) and Table 2 (double numbering).
- **Missing exhibits:** 
  1. **Flow Balance Table:** A table showing the top 5 sending and receiving regions would ground the data.
  2. **Event Study/Parallel Trends:** While a pre-trend test is in Table 7, a classic event study plot (coefficients by year) is standard for panel IV.

**Top 3 improvements:**
1. **Move Figure 7 (Map) to the main text.** It is the best way to show the "Drain" geography.
2. **Fix the formatting in Table 4.** Add the dependent variable mean and separate the labor market outcomes to avoid "unit-mixing" confusion.
3. **Clean up Table 2/Table 1.** Fix the redundant title and ensure all tables use `booktabs` styling with decimal alignment.