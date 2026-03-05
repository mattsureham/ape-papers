# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-05T15:47:13.727675
**Route:** Direct Google API + PDF
**Tokens:** 20477 in / 1809 out
**Response SHA256:** 6db3576cedb20deb

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Labor Market Outcomes by Race and CROWN Act Status"
**Page:** 12
- **Formatting:** Generally clean. Uses horizontal rules appropriately. Numbers are centered rather than decimal-aligned, which can make comparing magnitudes slightly harder.
- **Clarity:** Very high. The 2x2 structure (Pre/Post vs Black/White) is intuitive.
- **Storytelling:** Essential. It establishes the baseline "gaps" that the rest of the paper tries to close.
- **Labeling:** Clear. The note is comprehensive, explaining the 2020 exclusion and the composition of the "54" post-treatment observations.
- **Recommendation:** **REVISE**
  - Decimal-align all numerical values in the columns to improve readability.
  - Add a "Gap" column for both Pre and Post periods to explicitly show the disparities mentioned in the text (e.g., the 8.2 pp employment gap).

### Table 2: "CROWN Act Effects on Black-White Labor Market Gaps"
**Page:** 15
- **Formatting:** Professional journal style. Good use of panels to distinguish between estimators.
- **Clarity:** Good. It clearly shows the null on employment/earnings vs. the significant effect on occupations in Panel B.
- **Storytelling:** This is the "money table" of the paper. It highlights the central tension: aggregate nulls vs. compositional shifts.
- **Labeling:** Excellent. Significance stars are defined, and clustering is noted. 
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Event Study: CROWN Act Effects on Black-White Labor Market Gaps"
**Page:** 17
- **Formatting:** Clean 4-panel layout. Font sizes are a bit small, especially axis titles.
- **Clarity:** The use of "pp" and "log pts" in the Y-axis labels is excellent. The shaded 95% CIs are standard and clear.
- **Storytelling:** Crucial for validating the parallel trends assumption. Panel D clearly shows the "gradual" effect mentioned in the text.
- **Labeling:** Descriptive and includes the data source and 2020 omission note.
- **Recommendation:** **REVISE**
  - Increase the font size for the axis labels (ATT (pp)) and tick marks to ensure legibility when printed.
  - In Panel D, the Y-axis scale could be tightened to make the post-treatment upward trend more visually prominent.

### Table 3: "CROWN Act Effects on Employment Gap by Sex"
**Page:** 18
- **Formatting:** Standard formatting, consistent with Table 2.
- **Clarity:** High.
- **Storytelling:** Confirms the null is robust across genders.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**
  - This is a heterogeneity/robustness check. Given that it confirms a null finding, it doesn't need to take up a full page in the main text. The result can be summarized in one sentence in the text.

### Figure 2: "CROWN Act Effects on Employment Gap by Sex"
**Page:** 19
- **Formatting:** Colorful, but the overlapping CIs make it a bit "busy."
- **Clarity:** The legend is clear, but the red/blue overlap at event time 0-2 is messy.
- **Storytelling:** Visualizes the null by sex.
- **Labeling:** Good.
- **Recommendation:** **MOVE TO APPENDIX**
  - Like Table 3, this is secondary to the main argument. It belongs in the Heterogeneity Appendix (where it is already referenced as D.1).

### Table 4: "Robustness Checks"
**Page:** 20
- **Formatting:** A bit sparse. It's essentially a list of coefficients from other regressions.
- **Clarity:** High.
- **Storytelling:** Consolidates multiple "stress tests" into one place.
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - Add a column for "N" (Observations) for each row to show that the "Post-2020 only" sample is indeed smaller.
  - Consider merging this into the bottom of Table 2 as a "Panel C: Robustness" to save space.

### Figure 3: "CROWN Act Adoption Across U.S. States"
**Page:** 21
- **Formatting:** Modern bar chart. Gridlines are subtle.
- **Clarity:** Very high.
- **Storytelling:** Important for showing the "staggered" nature of the treatment. 
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS** (Though could be combined with a map).

### Figure 4: "Bacon Decomposition: Employment Gap TWFE Estimate"
**Page:** 22
- **Formatting:** Standard Bacon plot.
- **Clarity:** High for those familiar with the method.
- **Storytelling:** Necessary given the recent "DiD revolution" to prove the results aren't driven by "forbidden" comparisons.
- **Labeling:** Excellent legend.
- **Recommendation:** **MOVE TO APPENDIX**
  - The text states 82% of weights are "clean." This diagnostic belongs in the Identification Appendix.

### Figure 5: "Black-White Employment Gap by CROWN Act Adoption Cohort"
**Page:** 23
- **Formatting:** Spaghetti plot. Colors are distinguishable.
- **Clarity:** Moderate. The "2020 omitted" vertical line is helpful.
- **Storytelling:** Good "raw data" look, but the event study (Figure 1) is a more rigorous version of this.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**

### Figure 6: "Randomization Inference: Employment Gap"
**Page:** 24
- **Formatting:** Standard distribution plot.
- **Clarity:** Very high. The red line for "Actual" is a standard and effective convention.
- **Storytelling:** Visual proof of the p-value.
- **Labeling:** Excellent annotations.
- **Recommendation:** **MOVE TO APPENDIX**

---

## Appendix Exhibits

### Table 5: "CROWN Act Adoption Dates by State"
**Page:** 35
- **Formatting:** Simple list.
- **Clarity:** High.
- **Storytelling:** Essential reference for anyone replicating the study.
- **Labeling:** Precise.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 4 main tables, 6 main figures, 1 appendix table, 0 appendix figures (Note: several main figures are diagnostics that should be moved).
- **General quality:** High. The paper uses modern econometric visualizations (Bacon, Event Studies, RI distributions) that would satisfy top-tier reviewers.
- **Strongest exhibits:** Table 2 (The core results) and Figure 6 (Excellent annotation).
- **Weakest exhibits:** Figure 5 (A bit cluttered) and Table 3 (Could be a footnote).
- **Missing exhibits:** 
  1. **A Map:** A choropleth map of the U.S. colored by CROWN Act adoption year would be much more impactful than Figure 3 alone.
  2. **Triple-Diff Event Study:** Since the TWFE Triple-Diff is the only specification that finds significance (Table 2, Panel B), a Figure showing the lead/lag coefficients for *that* specific model is missing and likely requested by reviewers.

**Top 3 improvements:**
1. **Aggressive Appendix Management:** Move Figures 4, 5, 6 and Table 3 to the Appendix. This streamlines the main text to focus on the "Null Employment vs. Occupation Shift" story.
2. **Add a Map:** Replace or supplement Figure 3 with a U.S. map to show the geographic spread of the policy.
3. **Triple-Diff Visualization:** Create an event study plot specifically for the Triple-Difference estimator (the paper's strongest result) to show the pre-trends and the dynamic onset of the 1.28pp shift.