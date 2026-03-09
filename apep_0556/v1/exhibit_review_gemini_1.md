# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-09T16:06:24.220271
**Route:** Direct Google API + PDF
**Tokens:** 22037 in / 1972 out
**Response SHA256:** a68b945cb89e477c

---

This review evaluates the visual exhibits of the paper titled "Did India’s Health Mission Save Newborns? Evidence from the World’s Largest Community Health Worker Deployment" against the standards of top-tier economics journals.

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Health Indicators by NRHM Treatment Group"
**Page:** 8
- **Formatting:** Professional and clean. Uses standard LaTeX booktabs style. 
- **Clarity:** Excellent. The split between Panel A (Baseline) and Panel B (Endline) clearly shows the convergence in institutional delivery.
- **Storytelling:** Strong. It immediately justifies the DiD approach by showing the massive baseline gap and the subsequent catching-up.
- **Labeling:** Standard deviations are correctly noted. Source and group definitions are clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "NRHM Policy Timeline and Staggered Rollout"
**Page:** 13
- **Formatting:** The design is slightly unconventional for an AER/QJE paper (modern ggplot2 look). The dual-axis/floating dot approach is okay but could be more minimalist.
- **Clarity:** High. Clearly separates the "Policy" events from the "Data" (NFHS rounds) availability.
- **Storytelling:** Essential. It visualizes the identification strategy (the gap between Phase 1 and Phase 2).
- **Labeling:** Good.
- **Recommendation:** **REVISE**
  - Change the font of the internal labels (e.g., "NRHM Launch") to match the paper's serif font for a more integrated "journal" look.
  - Remove the background gridlines to increase the data-to-ink ratio.

### Table 2: "Effect of NRHM on Maternal Health Indicators"
**Page:** 14
- **Formatting:** Good, but the alignment of coefficients and standard errors is slightly off (not decimal-aligned).
- **Clarity:** Good. Covers the main specifications.
- **Storytelling:** This is the "money table." However, it mixes institutional delivery (Cols 1-3, 5) with ANC visits (Col 4).
- **Labeling:** Asterisks are standard. 
- **Recommendation:** **REVISE**
  - **Decimal Alignment:** Use `dcolumn` or `siunitx` in LaTeX to align numbers by the decimal point.
  - **Structure:** Use Panel A for "Institutional Delivery" (Cols 1, 2, 3, 5) and Panel B for "Antenatal Care" (the current Col 4). This avoids the confusion of changing outcome variables mid-table.
  - Add "State FE" and "Year FE" rows at the bottom with "Yes/No" to make the specification clear at a glance.

### Figure 2: "Institutional Delivery Trends by NRHM Treatment Group, 1993–2020"
**Page:** 14
- **Formatting:** Professional. Shaded confidence intervals are well-executed.
- **Clarity:** Very high. The "divergence" post-2006 is obvious.
- **Storytelling:** The primary visual proof of the paper's main claim.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Event Study: Differential Institutional Delivery Trends"
**Page:** 17
- **Formatting:** Clean. Standard DiD event study plot.
- **Clarity:** Excellent. It clearly shows the null pre-trend and the growing post-treatment effect.
- **Storytelling:** Essential for modern DiD papers.
- **Labeling:** Y-axis label "DiD Coefficient (pp)" is clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "National Neonatal Mortality Rate, 1990–2022"
**Page:** 18
- **Formatting:** Clean line plot.
- **Clarity:** High. 
- **Storytelling:** This figure is the "Paradox" half of the paper. It shows that while deliveries moved to facilities, the mortality trend didn't change its slope significantly.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Robustness Checks"
**Page:** 19
- **Formatting:** This is a "Summary of Results" table. 
- **Clarity:** Very high. It acts as a dashboard for the robustness section.
- **Storytelling:** Very helpful for the reader to see the "Pre-trend: Pass" and "RI: Significant" in one place.
- **Recommendation:** **KEEP AS-IS** (Though consider moving to the start of the Robustness section).

### Figure 5: "Randomization Inference: Distribution of Placebo Effects"
**Page:** 20
- **Formatting:** Clean histogram.
- **Clarity:** The red line clearly indicates the "Actual" estimate relative to the null distribution.
- **Storytelling:** Standard but effective proof of statistical significance in a small-cluster setting.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Leave-One-Out Sensitivity: Coefficient Stability"
**Page:** 21
- **Formatting:** Horizontal dot plot with whiskers.
- **Clarity:** High. Shows the estimate is not driven by any single state.
- **Storytelling:** Crucial given the size of states like Uttar Pradesh.
- **Recommendation:** **KEEP AS-IS**

### Figure 7: "JSY Incentive Intensity and Institutional Delivery Change"
**Page:** 23
- **Formatting:** Scatter plot with state labels.
- **Clarity:** Good, though state labels overlap slightly in the center-left.
- **Storytelling:** Provides the "Dose-Response" evidence. 
- **Recommendation:** **REVISE**
  - Use a "repel" algorithm for the state labels (e.g., `ggrepel` in R) to prevent overlapping names (e.g., "Man", "Meg", "Aru").

---

## Appendix Exhibits

### Table 4: "Pre-Trend Test: Differential Change in Institutional Delivery, 1993–1999"
**Page:** 34
- **Recommendation:** **KEEP AS-IS** (Standard appendix validation).

### Table 5: "Covariate Balance at Baseline (NFHS-3, 2005–06)"
**Page:** 35
- **Recommendation:** **KEEP AS-IS** (Correctly acknowledges the imbalance is expected).

### Table 6: "Sensitivity to Treatment Definition"
**Page:** 36
- **Recommendation:** **REMOVE** / **CONSOLIDATE**. This information is largely redundant with the main Table 2 and the text. If kept, merge it into Table 2 as extra columns or leave as a small appendix note.

### Table 10: "Standardized Effect Sizes for Main Outcomes"
**Page:** 40
- **Formatting:** Comprehensive but very text-heavy.
- **Clarity:** Low. It looks more like a "data dictionary" or "technical note" than a journal table.
- **Recommendation:** **REVISE**
  - Simplify the "Notes" section. 
  - This is actually quite a strong selling point (1.11 Standard Deviations). Consider moving a simplified version of this into the main text or a footnote in the results section.

---

## Overall Assessment

- **Exhibit count:** 2 main tables, 7 main figures, 8 appendix tables/figures (Total ~17 exhibits).
- **General quality:** Extremely high. The paper follows the "modern DiD" template perfectly (Timeline -> Trends -> Event Study -> Main Table -> RI -> Leave-one-out).
- **Strongest exhibits:** Figure 2 (Trends) and Figure 3 (Event Study).
- **Weakest exhibits:** Table 10 (Too cluttered) and Table 2 (Needs decimal alignment).

- **Missing exhibits:** 
  1. **A Map:** A map of India shaded by "High-Focus" vs. "Non-High-Focus" would be a standard Figure 1 in an AER/QJE paper to help international readers understand the geography (especially the Northeastern states' isolation).
  2. **Facility Quality Data Table:** The paper argues for a "Facility Quality Paradox." A table or figure showing the "16% of PHCs meet standards" (mentioned on p. 24) would provide empirical teeth to the "Discussion" section.

- **Top 3 improvements:**
  1. **Add a Treatment Map:** Show the 18 high-focus states geographically.
  2. **Refine Table 2:** Decimal-align numbers and use a Panel structure to separate Institutional Delivery from ANC visits.
  3. **Visual Data for the "Paradox":** Create a figure showing the lack of improvement in facility quality (e.g., doctor availability or electricity) over the same period to prove why mortality didn't fall.