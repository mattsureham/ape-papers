# Exhibit Review — Gemini 3 Flash (Round 2)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-11T10:30:45.202699
**Route:** Direct Google API + PDF
**Tokens:** 19437 in / 2104 out
**Response SHA256:** e80cb87e63469dad

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics"
**Page:** 9
- **Formatting:** Clean and professional. Proper horizontal rules. Decimal alignment is generally good, though the large values in GDP per capita and LFP create a wide gap.
- **Clarity:** Excellent. The units are clearly specified in the variable labels.
- **Storytelling:** Essential. It establishes the scale of the Erasmus outflow rate (approx. 3.7 per 1k youth) which helps the reader interpret the later $\beta$ of -0.39.
- **Labeling:** Good. Includes N for each variable.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "First Stage: Bartik Instrument and Erasmus Outflows"
**Page:** 13
- **Formatting:** Standard journal format. The use of "nuts2" and "year" for fixed effects is clear.
- **Clarity:** Good, though the "Model" row is somewhat redundant when the columns are already labeled by the independent variable of interest.
- **Storytelling:** Strong. Shows the power of both the growth and level versions of the instrument.
- **Labeling:** Clear. Standard error clustering is noted.
- **Recommendation:** **REVISE**
  - Change "nuts2" to "Region FE" and "year" to "Year FE" to look more like a final publication and less like raw regression output.

### Figure 1: "First-Stage Binscatter: Bartik Instrument and Erasmus Outflow Rate"
**Page:** 14
- **Formatting:** Clean ggplot style. The gray confidence ribbon is helpful.
- **Clarity:** High. Shows a clear linear relationship without being driven by outliers.
- **Storytelling:** Essential for IV papers to prove the first stage isn't a "black box" or driven by 2-3 extreme regions.
- **Labeling:** "residualized" is clearly noted.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Main Results: Effect of Erasmus Outflows on Regional Human Capital"
**Page:** 15
- **Formatting:** Excellent. Grouping columns (1)-(3) under one outcome and (4)-(5) under others is a pro-level move.
- **Clarity:** High. The inclusion of the 1st stage F-test in the table footer is standard and helpful.
- **Storytelling:** This is the "money" table. It shows the OLS vs 2SLS contrast and the extension to labor markets.
- **Labeling:** Note is comprehensive.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Reduced Form: Predicted Outflows and Tertiary Education Share"
**Page:** 16
- **Formatting:** Consistent with Figure 1.
- **Clarity:** Clear negative slope.
- **Storytelling:** Vital. It shows the raw relationship between the instrument and the outcome.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Placebo Test: Erasmus-Affected vs. Broader Cohort"
**Page:** 17
- **Formatting:** Professional.
- **Clarity:** Good.
- **Storytelling:** This is a key mechanism test. Comparing the 25-34 to 25-64 group provides the "dilution" evidence needed to rule out general regional decline.
- **Labeling:** Column headers are descriptive.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Cohort Dilution Test: Young (25–34) vs. Broader (25–64) Tertiary Share"
**Page:** 18
- **Formatting:** Clean coefficient plot. 
- **Clarity:** Immediate visual impact—the difference between the two coefficients is the paper's core identification argument.
- **Storytelling:** Effectively visualizes Table 4.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Heterogeneity: Effects by Regional Characteristics"
**Page:** 19
- **Formatting:** Consistent with other tables.
- **Clarity:** Splitting by "Peripheral" and "Core" is intuitive.
- **Storytelling:** Supports the "divergence" narrative—the effect is only present in poorer regions.
- **Labeling:** Detailed notes on "Peripheral" and "Net Senders" definitions.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Heterogeneity: 2SLS Estimates by Regional GDP Level"
**Page:** 20
- **Formatting:** Standard coefficient plot.
- **Clarity:** High.
- **Storytelling:** Visualizes the most important heterogeneity result.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

## Appendix Exhibits

### Figure 5: "Randomization Inference: Distribution of Permuted Coefficients"
**Page:** 22
- **Formatting:** Good. Red vertical line for observed $\beta$ is standard.
- **Clarity:** Clear evidence that the result isn't a fluke of shock assignment.
- **Storytelling:** Standard requirement for modern Bartik IV papers.
- **Labeling:** RI p-value is clearly displayed.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Leave-One-Country-Out Stability of the Main Estimate"
**Page:** 23
- **Formatting:** High-density plot. 
- **Clarity:** Impressively clear despite the number of countries.
- **Storytelling:** Proves no single country (like Italy or Poland) is driving the whole European result.
- **Labeling:** Use of country ISO codes is standard.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Robustness: Alternative Specifications"
**Page:** 32
- **Formatting:** Clean.
- **Clarity:** Each column tests a specific concern (COVID, shares, pre-trends).
- **Storytelling:** Essential "defensive" table.
- **Labeling:** Column (4) as "Pre-trend" is a great use of a table to show a null result.
- **Recommendation:** **KEEP AS-IS**

### Table 7: "Cross-Sectional Long-Difference Specification"
**Page:** 33
- **Formatting:** Standard.
- **Clarity:** Shows the failure of the cross-section, which justifies the panel approach.
- **Storytelling:** Good for transparency.
- **Labeling:** Clearly labeled as "IID standard errors."
- **Recommendation:** **KEEP AS-IS**

### Figure 7: "Net Erasmus+ Student Outflows by NUTS2 Region, 2014–2019"
**Page:** 34
- **Formatting:** High-quality map.
- **Clarity:** Color scale (Red for drain, Blue for gain) is intuitive.
- **Storytelling:** **Strongest visual in the paper.** It immediately shows the "South/East to North/West" flow.
- **Labeling:** Clear legend.
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - This should be "Figure 1" in the introduction or data section. It sets the stage for the entire paper's narrative.

### Table 8: "Standardized Effect Sizes"
**Page:** 35
- **Formatting:** Slightly cluttered with many columns of SDs.
- **Clarity:** The "Classification" column is helpful for non-specialists.
- **Storytelling:** Helps interpret the "economic significance" vs. just "statistical significance."
- **Labeling:** Extensive note.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 5 main tables, 4 main figures, 3 appendix tables, 3 appendix figures.
- **General quality:** Extremely high. The author follows "Best Practices for Modern IV" (Borusyak et al. 2022; Goldsmith-Pinkham et al. 2020) to a fault. The exhibits are clean, consistent, and logically ordered.
- **Strongest exhibits:** Figure 7 (Map) and Figure 3 (Cohort Dilution Plot).
- **Weakest exhibits:** Table 2 (minor "raw output" feel) and Table 7 (though its weakness is the point of the analysis).
- **Missing exhibits:** 
  1. **A Share Balance Table:** Since the paper relies on "Share Exogeneity," a table showing that pre-period shares are not correlated with regional baseline characteristics (e.g., initial industry mix or unemployment) would be standard.
  2. **First-Stage Table for Subsamples:** It would be good to see if the first stage remains strong in the "Peripheral" only sample.

### Top 3 Improvements:
1. **Move Figure 7 (The Map) to the Introduction:** It is too good to be hidden on page 34. It "hooks" the reader by visualizing the brain drain.
2. **Professionalize Table Headers:** Change technical shorthand like `nuts2` or `lfp` to "Region" and "Labor Force Participation" in all regression tables.
3. **Consolidate Table 4 and Figure 3:** In top journals, you often see the plot (Fig 3) and the regression (Table 4) combined or the plot placed very close to the table. Given the space, they are fine separate, but consider making the Plot the "Star" of the main text and moving the Table to the appendix if space is needed.