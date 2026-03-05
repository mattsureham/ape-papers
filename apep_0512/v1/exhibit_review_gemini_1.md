# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-05T12:14:49.964140
**Route:** Direct Google API + PDF
**Tokens:** 17357 in / 2049 out
**Response SHA256:** 443c34eeaa39fcf0

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics"
**Page:** 11
- **Formatting:** Clean and professional. Use of horizontal rules is appropriate for top journals.
- **Clarity:** Good. The split between Panel A (Prices) and Panel B (Tax Rates) is logical. 
- **Storytelling:** Essential. It establishes the scale of the reform (e.g., the massive jump in TF rates from 14.28% to 26.54%).
- **Labeling:** Clear. However, "Mean Price/m² (€)" should specify that it is for *apartments* in the label, not just the panel header.
- **Recommendation:** **REVISE**
  - Add standard deviations in parentheses below the means. Top journals require a sense of the spread, especially for the treatment variables (TH Rate).
  - Explicitly define $N$ (number of observations) in addition to the number of unique communes.

### Table 2: "Tax Capitalization into Property Prices"
**Page:** 14
- **Formatting:** Journal-standard. Number of observations and R-squared are clearly presented.
- **Clarity:** High. The comparison between weighted and unweighted models is standard.
- **Storytelling:** This is the core "result" table for Part A. It effectively shows the "marginal significance" mentioned in the abstract.
- **Labeling:** Standard errors are noted as being in parentheses. Significance stars are defined.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Event Study: Tax Capitalization into Property Prices"
**Page:** 15
- **Formatting:** Professional ggplot2-style. No excessive gridlines.
- **Clarity:** The "Reform onset" vertical line is helpful. The 95% CI bands are clearly visible.
- **Storytelling:** Crucial for the DiD identification. It shows the lack of pre-trends and the subsequent "fade" in capitalization.
- **Labeling:** Y-axis label is specific ($\beta_t$ log price/m²).
- **Recommendation:** **REVISE**
  - The Y-axis scale is very narrow (0.000 to 0.004). The "fade" in 2023-2024 is the most interesting part of the story; consider adding a horizontal dashed line at the pooled estimate level from Table 2 for comparison.

### Figure 2: "Property Price Trends by Pre-Reform TH Rate Quartile"
**Page:** 16
- **Formatting:** Clean. Colors (Q1-Q4) are distinguishable.
- **Clarity:** The "raw data" look is a good complement to the regression-based Figure 1.
- **Storytelling:** It shows that all communes followed a similar macro-trend (the 2021-2022 boom), justifying the use of year FEs.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Fiscal Displacement: Taxe Foncière Rate Response"
**Page:** 17
- **Formatting:** Excellent. Consistent with Table 2.
- **Clarity:** Logical. $N$ is much higher here (full REI panel), which is correctly noted.
- **Storytelling:** This is the "smoking gun" for the fiscal displacement argument. The coefficient (0.646) is the centerpiece of the paper's second half.
- **Labeling:** "TH Dependence" vs "TH Share" labels in rows should be made consistent with the text (the text uses "TH revenue share").
- **Recommendation:** **REVISE**
  - Clarify in the notes that the "TF Level" includes the mechanical departmental transfer in the post-period, whereas the "TF Change" accounts for it.

### Figure 3: "Event Study: Fiscal Displacement (TF Rate Response)"
**Page:** 17
- **Formatting:** Matches Figure 1 for consistency.
- **Clarity:** The massive jump in 2021 is the dominant visual feature.
- **Storytelling:** Essential. It visualizes the "ratchet effect" described in the text.
- **Labeling:** Y-axis units are clear.
- **Recommendation:** **REVISE**
  - There is a noticeable dip in 2016. The text mentions a "commune merger wave." This should be explicitly mentioned in the figure note to prevent readers from worrying about pre-trend violations.

### Figure 4: "Taxe Foncière Rate Trends by Pre-Reform TH Revenue Dependence"
**Page:** 18
- **Formatting:** Clean.
- **Clarity:** Very high. The "fan out" of the lines after 2021 clearly shows displacement.
- **Storytelling:** Strongly supports Table 3.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Net Incidence Decomposition"
**Page:** 19
- **Formatting:** Tabular summary of a calculation.
- **Clarity:** Useful, but "Offset share 14.8%" needs a clearer explanation of how it's derived from the coefficients.
- **Storytelling:** This is the "synthesis" exhibit. It brings Part A and Part B together.
- **Labeling:** Good.
- **Recommendation:** **REVISE**
  - Move the "Notes" that explain $\hat{\gamma}$ (the price elasticity to TF) to a more prominent position or incorporate it as a footnote, as the "wrong sign" on $\hat{\gamma}$ is a major caveat.

### Figure 5: "Net Incidence Decomposition"
**Page:** 20
- **Formatting:** Simple bar chart.
- **Clarity:** High.
- **Storytelling:** Potentially redundant with Table 4. While it visualizes the "net" effect, the "TF Fiscal Offset" bar is so small (due to the biased $\hat{\gamma}$) that the figure almost looks like it's showing no offset.
- **Labeling:** Good.
- **Recommendation:** **MOVE TO APPENDIX**
  - The text admits the decomposition is "illustrative only" because $\hat{\gamma}$ has the wrong sign. Keeping this in the main text might give too much weight to a non-identified structural parameter.

### Table 5: "Robustness: Tax Capitalization Estimates"
**Page:** 22
- **Formatting:** Consistent with main tables.
- **Clarity:** Good use of column headers to denote subsamples.
- **Storytelling:** Standard "AER-style" robustness table.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Figure 6: "Residential Transaction Volume, 2014–2024"
**Page:** 30
- **Formatting:** Stacked bar chart.
- **Clarity:** Good. Shows the COVID dip clearly.
- **Storytelling:** Important for showing that the "sample expansion" in 2021 (from aggregates to microdata) coincided with a general market boom, not just a data artifact.
- **Recommendation:** **KEEP AS-IS**

### Figure 7: "Distribution of Pre-Reform Taxe d'Habitation Rates"
**Page:** 31
- **Formatting:** Professional histogram.
- **Clarity:** High. The red dashed line for the median is helpful.
- **Storytelling:** Justifies the "continuous treatment" approach by showing the wide variation in tax rates.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 4 main tables, 5 main figures, 1 appendix table (implied by text, though Table 5 is technically in the text), 2 appendix figures.
- **General quality:** Extremely high. The paper follows the visual language of top-tier economics journals (AER/QJE) very closely. The consistency between figures (color schemes, labeling) is excellent.
- **Strongest exhibits:** Figure 3 (Event Study of TF) and Table 3. They tell the most compelling and "cleanest" part of the story.
- **Weakest exhibits:** Figure 5. It visualizes a calculation based on an incorrectly signed elasticity ($\hat{\gamma}$), which might distract from the stronger reduced-form results.
- **Missing exhibits:** 
    1. **A Map:** Given this is a French study with 35,000 communes, a heat map of pre-reform TH rates across France would be a "gold standard" addition for a journal like the AEJ.
    2. **First-Stage Figure:** A scatter plot showing the correlation between TH revenue loss and subsequent TF rate increases would solidify the "Fiscal Displacement" story.
- **Top 3 improvements:**
  1. **Add Standard Deviations to Table 1:** This is a basic requirement for descriptive tables in top journals.
  2. **Relocate Figure 5 to Appendix:** Don't let the problematic structural decomposition overshadow the high-quality DiD results in Figure 1 and Figure 3.
  3. **Address the 2016 dip in Figure 3 Note:** Proactively explain the "commune merger wave" in the figure notes to satisfy skeptical reviewers regarding pre-trends.