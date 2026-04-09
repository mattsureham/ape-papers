# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-04-09T02:36:23.801771
**Route:** Direct Google API + PDF
**Tokens:** 20997 in / 2292 out
**Response SHA256:** bfaccf066fd0c2ef

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics by Quota Exposure Quartile"
**Page:** 9
- **Formatting:** Clean and professional. Use of horizontal rules is appropriate.
- **Clarity:** Excellent. Grouping by exposure quartile immediately shows the reader the underlying differences between "treated" and "control" counties.
- **Storytelling:** Critical. It sets the stage by showing that high-exposure counties are more urban and have higher baseline scores, justifying the need for the fixed-effects strategy.
- **Labeling:** Clear. Units (points, rates, shares) are understandable.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Effect of Quota Exposure on Occupational Mobility, 1920–1930"
**Page:** 12
- **Formatting:** Number alignment is good. However, the variable name `I(I(age_1920^2))` is raw code and looks unprofessional for a top journal.
- **Clarity:** Logical progression from unconditional to fully controlled models.
- **Storytelling:** This is the "money" table for the null result. It is well-placed.
- **Labeling:** "delta_occscore" should be "$\Delta$ OCCSCORE". "Signif. Codes" are standard but the note should explicitly mention that standard errors are in parentheses.
- **Recommendation:** **REVISE**
  - Change `I(I(age_1920^2))` to "Age Squared".
  - Clean up LaTeX-style variable names (e.g., `statefip_1920` should be "State FE").

### Figure 1: "Distribution of $\Delta$ OCCSCORE by Quota Exposure Quartile"
**Page:** 13
- **Formatting:** The density plot is a bit "spiky." The legend is well-placed.
- **Clarity:** The message—that the distributions overlap almost perfectly—is clear.
- **Storytelling:** Good visual support for the null result in Table 2.
- **Labeling:** Axis labels are clear.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Alternative Outcomes: Occupational Mobility, Migration, and Homeownership"
**Page:** 14
- **Formatting:** Same issue with raw code names (`age_1920`, `log_pop`).
- **Clarity:** Combines five different outcomes. While logical, column (5) is the only significant result and is the pivot to the second half of the paper.
- **Storytelling:** This table acts as a bridge. It might be better to move the "Became Owner" result to its own table or group it with the decomposition in Table 5.
- **Labeling:** Ensure "delta_sei" is written as "$\Delta$ Duncan SEI".
- **Recommendation:** **REVISE**
  - Clean variable names.
  - Suggestion: Move column (5) to Table 5 to consolidate the homeownership story.

### Table 4: "Heterogeneous Effects by Race and Location"
**Page:** 16
- **Formatting:** Professional.
- **Clarity:** Easy to read.
- **Storytelling:** Necessary to show the null isn't driven by a specific subgroup.
- **Labeling:** "delta_occscore" needs cleaning.
- **Recommendation:** **KEEP AS-IS** (with minor label cleaning)

### Table 5: "Homeownership Mechanism Decomposition"
**Page:** 17
- **Formatting:** This is a very wide table (7 columns). It pushes the margins.
- **Clarity:** Slightly cluttered. Columns (1)-(3) are a different "story" than (4)-(7).
- **Storytelling:** This is the "hidden cost" evidence. It is very strong.
- **Labeling:** Use Panel A (Transitions) and Panel B (Heterogeneity) to make the table more readable.
- **Recommendation:** **REVISE**
  - Split into Panel A (Cols 1-3) and Panel B (Cols 4-7) within the same table to group the logic.

### Figure 2: "Residualized Homeownership Transition Rate by Quota Exposure Quintile"
**Page:** 18
- **Formatting:** Standard bar chart. 
- **Clarity:** The Y-axis values are very small (decimals), which can be hard to internalize.
- **Storytelling:** Effectively shows the non-linear "hit" to the highest exposure quintile.
- **Labeling:** Y-axis should perhaps be "Probability Change (pp)" to make the numbers (e.g., 0.4%) more intuitive.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Placebo Test: 1910–1920 (Pre-Quota Period)"
**Page:** 20
- **Formatting:** Consistent with earlier tables.
- **Clarity:** Strong contrast to Table 2.
- **Storytelling:** Vital for the "complementarity" argument.
- **Labeling:** Variable names need the same cleaning as Table 2.
- **Recommendation:** **REVISE**
  - Change "Quota Exposure (1920)" to "Exposure (1920)" in the row label for brevity.

### Figure 3: "Pre-Restriction Complementarity: Quota Exposure and Native Occupational Gains, 1910–1920"
**Page:** 22
- **Formatting:** High quality. The confidence interval shading is professional.
- **Clarity:** The binned scatterplot is the gold standard for this type of paper (AER style).
- **Storytelling:** Very persuasive.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Multi-Wave Event Study: Quota Exposure and Native Occupational Gains"
**Page:** 23
- **Formatting:** Clean.
- **Clarity:** Excellent. This is the "summary" figure of the paper's first half.
- **Storytelling:** High impact.
- **Recommendation:** **KEEP AS-IS**

### Table 7: "First Stage: Did Restriction Reduce Immigrant Presence?"
**Page:** 24
- **Formatting:** Standard.
- **Clarity:** The R-squared of 0.80 is a very strong first stage.
- **Storytelling:** Necessary for identification.
- **Recommendation:** **MOVE TO APPENDIX**
  - The first stage is visually summarized in Figure 5. The table is secondary for the main text flow.

### Figure 5: "First Stage: Change in Restricted-Origin Share vs. Quota Exposure"
**Page:** 25
- **Formatting:** Excellent.
- **Clarity:** Immediate visual proof of the "treatment."
- **Storytelling:** Strong.
- **Recommendation:** **KEEP AS-IS**

### Table 8: "Robustness Checks"
**Page:** 26
- **Formatting:** Use of panels is good.
- **Clarity:** Clean summary of many regressions.
- **Storytelling:** Standard for Section 8.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Leave-One-Origin-Out Robustness"
**Page:** 27
- **Formatting:** High professional standard.
- **Clarity:** Clears up concerns about any single group (like Italians or Poles) driving the result.
- **Recommendation:** **KEEP AS-IS**

### Figure 7: "Occupational Transition Matrix, 1920–1930"
**Page:** 29
- **Formatting:** Heatmap is clear.
- **Clarity:** A bit complex. The "Difference in transition probability" is a "triple-difference" concept that takes a moment to parse.
- **Storytelling:** This is very "mechanistic." 
- **Recommendation:** **MOVE TO APPENDIX**
  - It’s too detailed for the main text and distracts from the homeownership finding.

### Figure 8: "Distribution of Quota Exposure Across Counties"
**Page:** 30
- **Formatting:** Good.
- **Clarity:** Shows the skewness of the data.
- **Storytelling:** Helpful, but mostly supports Table 1.
- **Recommendation:** **MOVE TO APPENDIX**

---

## Appendix Exhibits

### Table 9: "Standardized Effect Sizes"
**Page:** 37
- **Recommendation:** **KEEP AS-IS**. Very helpful for interpreting the economic significance of the nulls.

### Table 10: "Auxiliary Regression Results..."
**Page:** 38
- **Recommendation:** **REVISE**. The "Moved" column (3) is actually quite important for the selective mobility argument. Consider referencing it more heavily.

### Table 11: "Robustness: 1910 Exposure Instrument..."
**Page:** 38
- **Recommendation:** **KEEP AS-IS**.

---

## Overall Assessment

- **Exhibit count:** 8 main tables, 7 main figures, 3 appendix tables, 0 appendix figures.
- **General quality:** Extremely high. The paper follows the "modern" style of top-5 journals, favoring binned scatterplots and clean coefficient plots over dense tables.
- **Strongest exhibits:** Figure 3 (Binned scatter), Figure 4 (Event study), Figure 6 (Leave-one-out).
- **Weakest exhibits:** Table 2 and Table 3 (due to raw code variable names) and Figure 7 (too much complexity for main text).
- **Missing exhibits:** A **Map of Quota Exposure** would be a standard and highly effective addition to Section 3. It would help the reader see the geography of the "Restrictionist Mirage."

**Top 3 improvements:**
1. **Clean raw code names:** Replace all instances of `I(I(age_1920^2))`, `statefip`, and `delta_occscore` with publication-quality LaTeX labels (e.g., "Age Squared", "State FE").
2. **Streamline the story:** Move Table 7, Figure 7, and Figure 8 to the Appendix to keep the main text focused on the "Occupational Null vs. Homeownership Cost" narrative.
3. **Add a Map:** Include a choropleth map of the United States showing `Quota Exposure` by county to ground the shift-share instrument geographically.