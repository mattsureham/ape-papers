# Exhibit Review — Gemini 3 Flash (Round 3)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-09T16:56:35.846110
**Route:** Direct Google API + PDF
**Tokens:** 22557 in / 1956 out
**Response SHA256:** 8960144808346b14

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Health Indicators by NRHM Treatment Group"
**Page:** 9
- **Formatting:** Clean, standard three-line LaTeX table. Number alignment is generally good, but standard deviations in parentheses should be decimal-aligned with the means for better vertical scanning.
- **Clarity:** Excellent. The use of Panel A (Baseline) and Panel B (Endline) clearly shows the convergence story before any regression is shown.
- **Storytelling:** Essential. It establishes the "pre-treatment" gap that the NRHM aimed to close.
- **Labeling:** Clear. Units (%) are included in headers.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "NRHM Policy Timeline and Data Coverage"
**Page:** 14
- **Formatting:** Modern and professional. The separation of "Policy" (red) and "Data" (blue) is effective.
- **Clarity:** High. It immediately explains the staggered rollout and why certain survey rounds are "baseline" vs. "post."
- **Storytelling:** Great "Table 0" equivalent. It helps the reader understand the identification strategy (the gap between Phase 1 and Phase 2 entry) visually.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Effect of NRHM on Maternal Health Indicators"
**Page:** 15
- **Formatting:** Standard journal format. The spacing between columns is a bit wide.
- **Clarity:** Good, but Column 4 (ANC) uses a different outcome than the others. While noted in the footer, it would be clearer to have an "Outcome" sub-header row.
- **Storytelling:** This is the "Money Table." It logically moves from all states to the preferred specification (excluding NE) and then to the continuous treatment.
- **Labeling:** Significance stars are standard. Note: "Num.Obs." is fine, but "Observations" is more common in *AER*.
- **Recommendation:** **REVISE**
  - Add a row above the coefficients labeled "Dependent Variable" to clearly distinguish between Institutional Delivery and ANC 4+.
  - Decimal-align the standard errors (currently centered but offset by the parentheses).

### Figure 2: "Institutional Delivery Trends by NRHM Treatment Group, 1993–2020"
**Page:** 15
- **Formatting:** Professional. Shaded confidence intervals are well-rendered.
- **Clarity:** The key message (parallel pre-trends, divergent post-trends) is visible in under 5 seconds.
- **Storytelling:** Essential evidence for the parallel trends assumption.
- **Labeling:** Y-axis clearly labeled. 
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Event Study: Differential Institutional Delivery Trends"
**Page:** 18
- **Formatting:** Standard coefficient plot.
- **Clarity:** Good. The inclusion of the "NRHM Launch" vertical line is helpful.
- **Storytelling:** Reinforces Figure 2 by showing the point estimates and their lack of significance in the pre-period.
- **Labeling:** The X-axis labels (Survey years) are clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "National Neonatal Mortality Rate, 1990–2022"
**Page:** 19
- **Formatting:** Clean line plot.
- **Clarity:** Very high.
- **Storytelling:** This is the "Paradox" figure. It shows that despite the massive shift in delivery location (Table 2), the mortality trend didn't break.
- **Labeling:** Excellent descriptive title.
- **Recommendation:** **KEEP AS-IS** (Central to the paper's "Facility Quality Paradox" hook).

### Table 3: "Robustness Checks"
**Page:** 20
- **Formatting:** Summary table style.
- **Clarity:** Very clear "Pass/Fail" logic for the reader.
- **Storytelling:** Good for a quick summary, but essentially replicates data found in the appendix. 
- **Labeling:** Good.
- **Recommendation:** **MOVE TO APPENDIX**
  - In a top-tier journal, this summary table is often seen as "hand-holding." The main text should focus on the primary results, and the reader should be directed to the detailed robustness tables in the appendix.

### Figure 5: "Randomization Inference: Distribution of Placebo Effects"
**Page:** 21
- **Formatting:** Clean histogram.
- **Clarity:** The red line for the "Actual" estimate makes the p-value visually intuitive.
- **Storytelling:** Addresses the "few clusters" concern (30-35 states).
- **Labeling:** Axis labels are clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Leave-One-Out Sensitivity: Coefficient Stability"
**Page:** 22
- **Formatting:** Standard dot-and-whisker plot.
- **Clarity:** Shows that no single state (like Uttar Pradesh) is driving the result.
- **Storytelling:** Strong robustness evidence.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 7: "JSY Incentive Intensity and Institutional Delivery Change"
**Page:** 24
- **Formatting:** Scatter plot with fitted line and state labels.
- **Clarity:** A bit cluttered due to state abbreviations (e.g., "Ass", "Bih"). 
- **Storytelling:** Visualizes the continuous treatment in Table 2, Col 3.
- **Labeling:** Good.
- **Recommendation:** **REVISE**
  - Increase the size of the state labels or use a "repel" algorithm to prevent overlapping (e.g., around the 25-50% baseline mark).

---

## Appendix Exhibits

### Table 4: "Pre-Trend Test: Differential Change in Institutional Delivery, 1993–1999"
**Page:** 35
- **Recommendation:** **KEEP AS-IS** (Standard falsification test).

### Table 5: "Covariate Balance at Baseline (NFHS-3, 2005–06)"
**Page:** 36
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - Top journals (QJE/AER) almost always require a balance table in the main text to show the "starting line" for the treatment and control groups. This supports the "negative selection" narrative in the text.

### Table 6: "Sensitivity to Treatment Definition"
**Page:** 37
- **Recommendation:** **REMOVE**
  - This is entirely redundant with Table 2 in the main text.

### Table 7: "Leave-One-Out Estimates: Dropping Each High-Focus State"
**Page:** 38
- **Recommendation:** **KEEP AS-IS** (Tabular version of Figure 6).

### Table 8: "Heterogeneity: EAG vs. Northeastern States"
**Page:** 39
- **Recommendation:** **KEEP AS-IS**

### Table 9: "Effect on ANC 4+ Visits"
**Page:** 40
- **Recommendation:** **KEEP AS-IS**

### Table 10: "Standardized Effect Sizes for Main Outcomes"
**Page:** 41
- **Formatting:** Comprehensive but very text-heavy.
- **Storytelling:** Useful for meta-analysis but rarely seen in this format in AER/QJE.
- **Recommendation:** **KEEP AS-IS** (useful for the appendix).

---

## Overall Assessment

- **Exhibit count:** 2 main tables, 7 main figures (after moves), 7 appendix tables, 0 appendix figures.
- **General quality:** Extremely high. The figures are modern (likely ggplot2) and follow the "Clean Data" aesthetic preferred by *Econometrica* and *AEJ*. Tables are well-organized but need slight alignment tweaks.
- **Strongest exhibits:** Figure 1 (Timeline) and Figure 4 (Mortality Trend). They set up the "Paradox" perfectly.
- **Weakest exhibits:** Table 6 (Redundant) and Figure 7 (Cluttered labels).
- **Missing exhibits:** A **Map of India** showing the Phase 1 (High-Focus) vs. Phase 2 states would be highly beneficial for readers unfamiliar with Indian geography.

**Top 3 Improvements:**
1. **Add a Treatment Map:** Create a Figure 0 showing the treatment assignment geographically.
2. **Promote Balance Table:** Move Table 5 to the main text (Section 3) to establish the baseline differences formally before the DiD results.
3. **Refine Table 2:** Add dependent variable headers and decimal-align the standard errors to meet the highest professional standard.