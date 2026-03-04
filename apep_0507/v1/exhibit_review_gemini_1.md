# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-04T20:08:02.385717
**Route:** Direct Google API + PDF
**Tokens:** 17877 in / 1966 out
**Response SHA256:** 1434cf222aa681d3

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics"
**Page:** 9
- **Formatting:** Clean and professional. The horizontal lines follow standard academic style (booktabs).
- **Clarity:** Excellent. It clearly partitions the sample by treatment status and pre/post periods.
- **Storytelling:** Vital for establishing the "Ever-merged" group’s baseline characteristics. It shows they are larger than never-merged units, which justifies the use of population controls later.
- **Labeling:** Good. It includes N for both observations and municipalities.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Effect of Municipal Mergers on Referendum Turnout"
**Page:** 14
- **Formatting:** Standard professional layout. Standard errors are correctly in parentheses.
- **Clarity:** High. The progression from simple FE to Canton-Vote FE to population controls is logical.
- **Storytelling:** This is the core baseline result. It establishes the ~1.6 pp decline.
- **Labeling:** "turnout_pct" as a dependent variable label is a bit "code-like." It should be renamed to "Referendum Turnout (%)" for a cleaner look. Significance stars are well-defined.
- **Recommendation:** **REVISE**
  - Change "turnout_pct" to "Referendum Turnout (%)".
  - Decimal-align the coefficients and standard errors.

### Table 3: "Sun-Abraham Interaction-Weighted Estimates"
**Page:** 15
- **Formatting:** Professional.
- **Clarity:** Good, but it feels slightly redundant as a standalone table given Table 2.
- **Storytelling:** Important for robustness against staggered DiD bias, but the paper now has several small tables (2, 3, 4) that show variations of the same "ATT."
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - **Consolidation Opportunity:** Consider merging Tables 2 and 3. You could have Columns 1-3 as TWFE and Columns 4-5 as Sun-Abraham in a single "Main Results" table. This allows the reader to compare the bias-corrected estimates to the baseline in one glance.

### Table 4: "Callaway and Sant’Anna (2021) Estimates"
**Page:** 15
- **Formatting:** A bit sparse. It only contains one main estimate.
- **Clarity:** Clear, but takes up a lot of vertical space for very little data.
- **Storytelling:** Confirms the result with a third estimator.
- **Labeling:** "Bootstrap SEs" mentioned in notes is good.
- **Recommendation:** **MOVE TO APPENDIX** or **CONSOLIDATE**.
  - If you consolidate Tables 2 and 3 into a "Main Results" table, Table 4 can be a footnote or a single row in that consolidated table. As it stands, it doesn't justify its own table in the main text of a top journal.

### Figure 1: "Event-Study Estimates: Effect of Mergers on Turnout"
**Page:** 16
- **Formatting:** Good use of shaded confidence intervals. The red dotted line at $t=0$ is standard.
- **Clarity:** Excellent. The discrete jump at $t=0$ is visually striking.
- **Storytelling:** This is the "money plot" of the paper. It proves the parallel trends and the persistence of the effect.
- **Labeling:** Y-axis "Effect on voter turnout (pp)" is clear. 
- **Recommendation:** **KEEP AS-IS** (Consider making the markers slightly larger for QJE/AER style).

### Figure 2: "Event-Study Estimates: Callaway and Sant’Anna"
**Page:** 17
- **Formatting:** Identical style to Figure 1 but in red.
- **Clarity:** Clear.
- **Storytelling:** Redundant with Figure 1. While the estimators differ, the "story" (parallel trends + jump) is identical.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**
  - Having two nearly identical event study plots in the main text is unnecessary. Figure 1 (Sun-Abraham) is sufficient for the main narrative.

### Figure 3: "Raw Turnout Trends: Merged vs. Never-Merged Municipalities"
**Page:** 18
- **Formatting:** Good use of colors. 
- **Clarity:** A bit "busy" due to the high frequency of Swiss referendums.
- **Storytelling:** Very important. It shows the reader what the raw data looks like before the "black box" of DiD estimators. It validates the parallel trends visually.
- **Labeling:** Legend is clear.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Heterogeneous and Dynamic Treatment Effects"
**Page:** 19
- **Formatting:** Professional.
- **Clarity:** Logical grouping of columns.
- **Storytelling:** Essential for the mechanism section. It shows that the effect is driven by "Small" municipalities and stays stable over time.
- **Labeling:** Note that "current_bfs" in the FE section is a variable name from the code; change to "Municipality FE".
- **Recommendation:** **REVISE**
  - Rename "current_bfs" to "Municipality FE".
  - Ensure "Post-merger" in Column 1 and 2 is defined as the baseline category for the interaction.

### Figure 4: "Heterogeneous Event-Study Estimates by Merger Size"
**Page:** 20
- **Formatting:** Multi-line event study.
- **Clarity:** This is very cluttered. The confidence intervals overlap significantly, making it hard to distinguish the "Medium" and "Small" groups.
- **Storytelling:** Important for showing that "Large" mergers have the most negative impact.
- **Labeling:** Legend is clear.
- **Recommendation:** **REVISE**
  - Use different line styles (solid, dashed, dotted) in addition to colors.
  - Consider splitting this into a 3-panel plot (Small, Medium, Large) arranged vertically to avoid the "spaghetti" effect of overlapping CIs.

### Table 6: "Robustness Checks"
**Page:** 21
- **Formatting:** Professional.
- **Clarity:** High. Clear comparison across different subsamples and clustering.
- **Storytelling:** Standard for top-tier papers to show results aren't driven by Latin/German split or SE clustering.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Figure 5: "Distribution of Municipal Merger Cohorts"
**Page:** 30
- **Formatting:** Clean bar chart.
- **Clarity:** Very high.
- **Storytelling:** Useful for showing the reader that treatment is truly staggered across the entire 30-year window.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Cohort-Specific Treatment Effects"
**Page:** 31
- **Formatting:** Standard dot-and-whisker plot.
- **Clarity:** Hard to read because there are so many cohorts. Some CIs are huge.
- **Storytelling:** Good for transparency (showing no single year is an outlier), but not a "key" result.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 6 main tables, 4 main figures, 0 appendix tables, 2 appendix figures.
- **General quality:** High. The tables follow the "minimum ink" principle of top journals. The figures are modern and use appropriate transparency for CIs.
- **Strongest exhibits:** Figure 1 (Event Study) and Table 1 (Summary Stats).
- **Weakest exhibits:** Figure 4 (cluttered) and Table 4 (too sparse).
- **Missing exhibits:** 
    1. **Map of Switzerland:** A map showing which municipalities merged (perhaps shaded by decade) would be extremely helpful for a non-Swiss audience to understand the geographic variation.
    2. **Balance Table:** A more formal table testing differences in means (with p-values) for treated vs. control units beyond just the "Summary Stats" would be standard for a DiD paper.

- **Top 3 improvements:**
  1. **Consolidate Results:** Merge Tables 2, 3, and 4 into a single "Main Results" table. This makes the paper feel tighter and allows for direct comparison of estimators.
  2. **De-clutter Figure 4:** Split the heterogeneous event study into panels. The current version is too messy for a top journal.
  3. **Clean Variable Names:** Remove all "code-speak" (e.g., `turnout_pct`, `current_bfs`) from table headers and replace with plain English academic labels.