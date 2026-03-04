# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-04T11:02:58.331498
**Route:** Direct Google API + PDF
**Tokens:** 18917 in / 1837 out
**Response SHA256:** 1c3a2935587ad494

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Pre-Treatment Descriptive Statistics by Treatment Group (2010–2015)"
**Page:** 11
- **Formatting:** Clean and professional. Uses horizontal booktabs style lines.
- **Clarity:** The "group" labels are intuitive, and the choice of columns (Mean vs. SD) is standard.
- **Storytelling:** Essential. It validates the "pastoral" classification by showing the massive difference in baseline violence between pastoral and non-pastoral LGAs.
- **Labeling:** Good. "N (LGA-years)" clarifies the unit of observation.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Effect of Anti-Open Grazing Laws on Violence: Triple-Difference Estimates"
**Page:** 14
- **Formatting:** Excellent. Standard errors are in parentheses; significance stars are used correctly. Decimal alignment is good.
- **Clarity:** The progression from Column 1 (simple DD) to Column 3 (preferred DDD) tells a clear story of why the state-by-year fixed effects are necessary.
- **Storytelling:** This is the "money table" of the paper. It includes the main result, the intensity margin (deaths), and the placebo test in one view.
- **Labeling:** The table notes are comprehensive, defining the "Post x Treated" and "Pastoral" indicators well.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Dynamic Treatment Effects: Non-State Violence (Callaway-Sant’Anna)"
**Page:** 16
- **Formatting:** Professional. Uses simultaneous confidence intervals which is the current "best practice" for CS estimators.
- **Clarity:** The red dashed line at $t=-1$ clearly separates pre- and post-periods. However, the y-axis label "ATT (non-state violence events)" is a bit cramped.
- **Storytelling:** Crucial for identification. It visually confirms the lack of pre-trends.
- **Labeling:** Good, but the subtitle "Callaway-Sant'Anna (2021) estimator..." is a bit small.
- **Recommendation:** **REVISE**
  - Increase the font size of the axis labels and the subtitle.
  - Ensure the "0" line on the y-axis is a slightly heavier weight to make the null hypothesis visually prominent.

### Figure 2: "Placebo Event Study: State-Based Violence (Should Be Null)"
**Page:** 17
- **Formatting:** Consistent with Figure 1.
- **Clarity:** High. The caption "(Should Be Null)" helps the reader immediately understand the goal.
- **Storytelling:** Important for specificity. It shows the laws don't just reduce "all conflict" (which might imply a general security crackdown) but specifically farmer-herder conflict.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Non-State Violence Trends by Anti-Grazing Law Adoption Group"
**Page:** 18
- **Formatting:** Good use of shaded confidence intervals. The vertical dashed lines for specific policy shocks are helpful.
- **Clarity:** The "Early Adopter" spike in 2018 is very prominent, which is explained well in the text but might look like a failure of the law to a casual reader.
- **Storytelling:** Useful for raw data visualization before the regressions.
- **Labeling:** Legend is clear. 
- **Recommendation:** **REVISE**
  - The label "Benue law (Nov 2017)" points to the spike. Consider adding a small annotation or arrow clarifying that this spike represents the "implementation period upheaval" mentioned in the text to prevent misinterpretation.

### Figure 4: "Randomization Inference: Distribution of Permuted Coefficients"
**Page:** 19
- **Formatting:** Standard histogram. Red dashed line for the actual estimate is mandatory for this exhibit type.
- **Clarity:** Very high.
- **Storytelling:** Critical given the small number of clusters (37 states). It proves the result isn't a fluke of the specific state groupings.
- **Labeling:** Titles and notes are perfect.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Leave-One-State-Out: DDD Coefficient Stability"
**Page:** 20
- **Formatting:** Clean dot plot.
- **Clarity:** High. Shows that no single state (like Benue) is carrying the entire result.
- **Storytelling:** Standard robustness for conflict papers where one or two "high-intensity" regions often drive everything.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Table 3: "Robustness and Sensitivity Checks"
**Page:** 21
- **Formatting:** This is more of a summary table than a regression table.
- **Clarity:** Good for a quick scan of coefficients across different models.
- **Storytelling:** Consolidates multiple robustness checks (Log, SGF sub-sample) into one view.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS** (Wait—consider promoting to Main Text if space allows, as it summarizes the "strength" of the paper's findings).

### Table 4: "Callaway-Sant’Anna ATT Estimates: State-Year Level"
**Page:** 22
- **Formatting:** Simple 2-row table.
- **Clarity:** High.
- **Storytelling:** Explains the discrepancy between the aggregate state-level effects and the localized DDD effects.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Anti-Open Grazing Law Adoption by State"
**Page:** 31
- **Formatting:** List-style table.
- **Clarity:** Excellent reference for the reader.
- **Storytelling:** Documents the "staggered" nature of the treatment.
- **Labeling:** Source notes are good.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Anti-Open Grazing Laws and Farmer-Herder Violence in Nigeria"
**Page:** 33
- **Formatting:** Excellent choropleth map. The color coding is distinct.
- **Clarity:** High. Overlaying the raw conflict counts (numbers in parentheses) adds a layer of "truth" to the geographic categorization.
- **Storytelling:** This is a very strong visual. In many top journals, this would be Figure 1 in the main text to set the stage.
- **Labeling:** Good.
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - This map is more informative than Figure 3 for a reader's first introduction to the Nigerian context. It should be Figure 1.

---

## Overall Assessment

- **Exhibit count:** 2 main tables, 5 main figures, 3 appendix tables, 1 appendix figure.
- **General quality:** Extremely high. The exhibits follow the "AER style" (minimalist, no gridlines, focused on the estimate).
- **Strongest exhibits:** Table 2 (Comprehensive results) and Figure 6 (The Map).
- **Weakest exhibits:** Figure 1 (y-axis labels too small).
- **Missing exhibits:** A **Map of Pastoral Zones vs. Non-Pastoral Zones** at the LGA level. While the state-level map (Figure 6) is great, the DDD relies on the *within-state* variation between LGAs. A map showing which LGAs were classified as "Pastoral" based on the criteria in Section 3.4 would make the identification strategy much more transparent.

**Top 3 improvements:**
1.  **Promote Figure 6 (The Map) to the main text** (suggested Figure 1) and add an additional panel to it showing the LGA-level "Pastoral Zone" classification.
2.  **Visual Polish on Figures 1 and 2:** Increase font sizes for all labels and ensure the 95% CI bars are not so thin they disappear in print.
3.  **Standard Error Clarification:** In Table 2, explicitly state in the note that standard errors are clustered at the state level (this is in the text, but the table note should be self-contained).