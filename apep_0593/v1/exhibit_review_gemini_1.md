# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-11T10:12:29.706135
**Route:** Direct Google API + PDF
**Tokens:** 18397 in / 1890 out
**Response SHA256:** 5f2ff9853c8c55bd

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Figure 1: "Classification of NUTS2 Regions by Border Type"
**Page:** 8
- **Formatting:** Clean layout. The use of a map is appropriate for spatial DiD papers.
- **Clarity:** The legend is clear, and the color palette (Orange/Blue/Gray) is distinguishable even for those with color vision deficiencies.
- **Storytelling:** This is a crucial "visual identification" exhibit. It justifies the spatial variation used in the paper.
- **Labeling:** Legend is clear. 
- **Recommendation:** **KEEP AS-IS**

### Table 1: "Summary Statistics: Border vs. Interior NUTS2 Regions, 2012–2019"
**Page:** 9
- **Formatting:** Standard professional layout. Numbers are cleanly presented.
- **Clarity:** Easy to compare groups. 
- **Storytelling:** Essential for showing balance (or lack thereof) between treated and control units. It supports the transition to the log-specification by showing large standard deviations relative to means.
- **Labeling:** Clear units (EUR M, people, etc.). Note explains the data source and sample period.
- **Recommendation:** **REVISE**
  - **Specific changes:** Add a "Difference" column (Border minus Interior) with a t-test for the difference in means. This is standard in top journals to formally demonstrate "balance" or identify specific level differences.

### Table 2: "Effect of Roaming Abolition on Foreign Tourist Nights"
**Page:** 12
- **Formatting:** Professional headers. Use of "Fixed-effects" and "Fit statistics" sections is excellent (AER-style).
- **Clarity:** Logarithmic interpretation is clear. The layout is logical, moving from simple DiD to more demanding fixed effects.
- **Storytelling:** This is the "Money Table." It clearly presents the null result across specifications. 
- **Labeling:** Significance stars and clustering are well-defined.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Event Study: Effect of RLAH on Foreign Tourist Nights in Border Regions"
**Page:** 14
- **Formatting:** Clean white background. Point-and-whisker plot is standard.
- **Clarity:** The -3 year outlier/dip is very visually prominent. It draws the eye away from the post-treatment null, which is the actual story.
- **Storytelling:** Crucial for validating the parallel trends assumption.
- **Labeling:** Clear axis labels and reference period noted.
- **Recommendation:** **REVISE**
  - **Specific changes:** The shaded confidence interval in the pre-period (specifically around year -3) looks like a polygon fill error or an extreme outlier. Re-check the data for that year or use standard whiskers instead of a shaded area if the variance is that localized, as it currently looks like a "glitch" in the visual.

### Figure 3: "Raw Trends: Foreign Tourist Nights in Border vs. Interior Regions"
**Page:** 15
- **Formatting:** Good use of indexing (2016=100) to show parallel trends in levels.
- **Clarity:** Very high. The message "they were moving together before and after" is clear in 2 seconds.
- **Storytelling:** Excellent "transparent" evidence that supplements the regression results.
- **Labeling:** Clear and descriptive.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Border Comparison and Matched Sample"
**Page:** 16
- **Formatting:** Consistent with Table 2.
- **Clarity:** Logical grouping of robustness checks.
- **Storytelling:** Supports the main result by showing it holds in restricted/matched samples.
- **Labeling:** Clearly defined columns.
- **Recommendation:** **KEEP AS-IS** (Though could be moved to Appendix to save space if needed for a shorter letter format).

### Figure 4: "Placebo: Domestic Tourist Nights in Border vs. Interior Regions"
**Page:** 16
- **Formatting:** Identical to Figure 3 for consistency.
- **Clarity:** There is a weird "zero-drop" at the start of the 2012 line for the interior group (blue line).
- **Storytelling:** Vital placebo check.
- **Labeling:** Axis labels are clear.
- **Recommendation:** **REVISE**
  - **Specific changes:** Fix the data point for 2012 for "Interior regions." It appears to be plotted at zero, which breaks the trend line and looks like a coding error.

### Figure 5: "Leave-One-Country-Out Robustness"
**Page:** 21
- **Formatting:** Good use of horizontal forest plot.
- **Clarity:** Easy to see that no single country is driving a significant result.
- **Storytelling:** Standard robustness for European cross-country studies.
- **Labeling:** All countries labeled with ISO codes.
- **Recommendation:** **MOVE TO APPENDIX**
  - **Reason:** While good, it takes up nearly a full page and confirms what the reader already suspects given the tight null. This is a classic "Appendix C" exhibit to improve main text flow.

---

## Appendix Exhibits

### Figure 6: "Event Study: Continuous Treatment (Pre-Treatment Foreign Share)"
**Page:** 30
- **Formatting:** Consistent with Figure 2.
- **Clarity:** Again, the shaded CI at year -3 is massive and distracting.
- **Storytelling:** Parallel trends for the continuous version of the model.
- **Recommendation:** **REVISE**
  - **Specific changes:** Match the whisker style to Figure 2 (after fixing Figure 2).

### Table 4: "Leave-One-Country-Out Robustness"
**Page:** 31
- **Formatting:** Simple list. 
- **Clarity:** Redundant with Figure 5.
- **Storytelling:** Pure data version of Figure 5.
- **Recommendation:** **REMOVE**
  - **Reason:** Figure 5 is much better at conveying the lack of influence from any one country. Keeping both is redundant.

### Table 5: "Placebo Test: Fake Treatment at 2015"
**Page:** 32
- **Formatting:** Journal ready.
- **Clarity:** High.
- **Storytelling:** Supports the pre-trend argument.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Standardized Effect Sizes"
**Page:** 33
- **Formatting:** Different style from previous tables (uses gridlines).
- **Clarity:** Dense notes.
- **Storytelling:** Helps interpret the "zero" by showing how small the point estimates are in SD units.
- **Recommendation:** **REVISE**
  - **Specific changes:** Remove the vertical gridlines to match the "Booktabs" style of Tables 1-3 and 5.

---

## Overall Assessment

- **Exhibit count:** 3 main tables, 5 main figures, 3 appendix tables, 1 appendix figure
- **General quality:** Extremely high. The paper follows the visual conventions of top-tier empirical journals (AER/AEJ) very closely. The tables are particularly well-formatted.
- **Strongest exhibits:** Figure 1 (Map) and Table 2 (Main Results).
- **Weakest exhibits:** Figure 2 and Figure 6 (the Year -3 CI issue) and the 2012 data point in Figure 4.
- **Missing exhibits:** A **Mechanism Table**. The paper discusses three mechanisms (Inframarginal costs, Adaptation, Binding constraints). A table showing the 490% surge in data (the "first stage" that fails to pass through) would be a powerful visual way to contrast the "Digital Response" vs. the "Physical Response."

**Top 3 improvements:**
1. **Fix the "Ghost" data points:** Address the 2012 zero-drop in Figure 4 and the wild CI in year -3 of the event studies. These look like data/coding artifacts and undermine the professionalism of the exhibits.
2. **Consolidate Robustness:** Move Figure 5 to the Appendix and remove Table 4. The main text is slightly "figure-heavy" for a null result paper.
3. **Add a "First Stage" Visual:** Create a table or figure explicitly showing the 490% increase in data usage (using the BEREC data mentioned in text). This creates the "puzzle" that the rest of the paper then solves with the null tourism result.