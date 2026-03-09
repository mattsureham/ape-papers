# Exhibit Review — Gemini 3 Flash (Round 2)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-09T16:12:14.549416
**Route:** Direct Google API + PDF
**Tokens:** 22037 in / 2069 out
**Response SHA256:** 0f057b61e7dda76f

---

As a visual exhibit advisor for top-tier economics journals, I have reviewed the 17 exhibits in your paper. Overall, the paper is in excellent shape; it uses modern DiD visualizations (event studies, randomization inference, leave-one-out) that are standard for the *AER* or *QJE*.

However, several exhibits suffer from "raw output" syndrome—labels and formatting that look like default software settings rather than polished, journal-ready graphics.

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Health Indicators by NRHM Treatment Group"
**Page:** 8
- **Formatting:** Clean, uses booktabs style. Standard deviations in parentheses is standard.
- **Clarity:** Logical panel structure (Baseline vs. Endline).
- **Storytelling:** Effectively sets up the "negative selection" (High-focus states started much worse).
- **Labeling:** Good. "Inst. Delivery (%)" is clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "NRHM Policy Timeline and Staggered Rollout"
**Page:** 13
- **Formatting:** Poor. The text overlapping the lines (e.g., "JSY Scale-Up", "ASHA Deployment") looks unprofessional. The vertical placement of "Data" vs "Policy" dots is arbitrary.
- **Clarity:** Low. The message is simple, but the execution is cluttered.
- **Storytelling:** Vital for a staggered DiD paper, but needs to be cleaner.
- **Labeling:** Axis labels are missing (the y-axis has no label or scale).
- **Recommendation:** **REVISE**
  - Remove the horizontal lines through the middle.
  - Use a standard timeline format where "Policy Events" are above a single timeline and "Data Rounds" are below it.
  - Ensure no text overlaps with any lines or markers.

### Table 2: "Effect of NRHM on Maternal Health Indicators"
**Page:** 14
- **Formatting:** Standard. Decimal alignment is decent but could be tighter.
- **Clarity:** Column numbers (1)-(5) are clear.
- **Storytelling:** This is the "Money Table." It tries to do a lot (Binary, Continuous, ANC outcome, and Full Panel). 
- **Labeling:** The note is a bit sparse. It needs to explicitly state that all columns include State and Year Fixed Effects.
- **Recommendation:** **REVISE**
  - Add a row for "State FEs" and "Year FEs" with "Yes/Yes" to make the specification clear at a glance.
  - Group Columns (1), (2), and (5) under a "Binary Treatment" header and (3) under "Intensity."

### Figure 2: "Institutional Delivery Trends by NRHM Treatment Group, 1993–2020"
**Page:** 14
- **Formatting:** Good use of shaded confidence intervals. 
- **Clarity:** Very high. The "break" after 2006 is obvious.
- **Storytelling:** This is your strongest figure. It proves the parallel trends and the treatment effect visually.
- **Labeling:** Clear. 
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Event Study: Differential Institutional Delivery Trends"
**Page:** 17
- **Formatting:** Professional. Point estimates with CIs are standard.
- **Clarity:** High. 
- **Storytelling:** Essential for validating the DiD design.
- **Labeling:** "DiD Coefficient (pp)" is a great y-axis label.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "National Neonatal Mortality Rate, 1990–2022"
**Page:** 18
- **Formatting:** Clean.
- **Clarity:** High.
- **Storytelling:** Important for the "Facility Quality Paradox" argument. It shows that mortality was declining *anyway*.
- **Labeling:** Descriptive and accurate.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Robustness Checks"
**Page:** 19
- **Formatting:** This is a "summary of results" table. While helpful, journals often prefer these results to be in their own full tables in the appendix.
- **Clarity:** Very high.
- **Storytelling:** Good "at-a-glance" verification for a busy reviewer.
- **Labeling:** Define "Pass" and "Stable" more formally in the note.
- **Recommendation:** **MOVE TO APPENDIX** (as a summary) or **REVISE** into a more formal table.

### Figure 5: "Randomization Inference: Distribution of Placebo Effects"
**Page:** 20
- **Formatting:** Standard ggplot2 histogram. 
- **Clarity:** The red line clearly shows the actual estimate is an outlier.
- **Storytelling:** Excellent for addressing the "few clusters" concern.
- **Labeling:** High quality.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Leave-One-Out Sensitivity: Coefficient Stability"
**Page:** 21
- **Formatting:** Clean "caterpillar" plot.
- **Clarity:** Shows high stability.
- **Storytelling:** Prevents the "one state driving the result" critique.
- **Labeling:** "Dropped State" on Y-axis is correct.
- **Recommendation:** **KEEP AS-IS**

### Figure 7: "JSY Incentive Intensity and Institutional Delivery Change"
**Page:** 23
- **Formatting:** Cluttered. The state abbreviations (e.g., "Ass", "Bih") overlap each other significantly in the top left.
- **Clarity:** Low due to overlap.
- **Storytelling:** Good visualization of the "Intensity" specification.
- **Labeling:** Y-axis "Change in Delivery Rate (pp)" is clear.
- **Recommendation:** **REVISE**
  - Use `ggrepel` or a similar tool to prevent label overlap.
  - Increase the size of the dots and the contrast between the two colors.

---

## Appendix Exhibits

### Table 4: "Pre-Trend Test: Differential Change..."
**Page:** 34
- **Recommendation:** **KEEP AS-IS**. Standard falsification test.

### Table 5: "Covariate Balance at Baseline"
**Page:** 35
- **Recommendation:** **PROMOTE TO MAIN TEXT**. Reviewers always look for a balance table early on. It should ideally be Table 2, after Summary Stats.

### Table 6: "Sensitivity to Treatment Definition"
**Page:** 36
- **Recommendation:** **REMOVE**. This repeats exactly what is already in Table 2 (Columns 1, 2, and 3). Redundancy is the enemy of a tight paper.

### Table 7: "Leave-One-Out Estimates..."
**Page:** 37
- **Recommendation:** **KEEP AS-IS**. Good supporting data for Figure 6.

### Table 8: "Heterogeneity: EAG vs. Northeastern States"
**Page:** 38
- **Recommendation:** **KEEP AS-IS**. Explains why the NE states are excluded in the preferred spec.

### Table 9: "Effect on ANC 4+ Visits"
**Page:** 39
- **Recommendation:** **REMOVE**. This is already in Table 2 (Column 4).

### Table 10: "Standardized Effect Sizes for Main Outcomes"
**Page:** 40
- **Formatting:** Too much text in a table format (the "Research question" and "Method" sections).
- **Recommendation:** **REVISE**. Convert this into a clean table of just the numbers. Move the "Research Question/Treatment/Data" text into a proper Table Note or the main text.

---

# Overall Assessment

- **Exhibit count:** 2 main tables, 7 main figures, 7 appendix tables, 0 appendix figures.
- **General quality:** High. The paper uses a very "modern" econometrics toolkit. The figures are generally more compelling than the tables.
- **Strongest exhibits:** Figure 2 (Trends) and Figure 5 (Randomization Inference).
- **Weakest exhibits:** Figure 1 (Timeline) and Table 10 (Standardized Effects).
- **Missing exhibits:** 
    - **Map of India:** A paper about "High-Focus" vs. "Non-High-Focus" states *must* have a map showing which states are in which group. This is standard for any regional development paper in top journals.
    - **Regression Discontinuity Plot (Optional):** If the 18 states were chosen based on a specific index cutoff, a plot showing that cutoff would be powerful.

### Top 3 Improvements:
1.  **Consolidate Table 2:** It currently contains results that are then repeated in Appendix Tables 6 and 9. Keep the main table focused and use the appendix for the deep dives.
2.  **Add a Map:** Visualize the treatment assignment (High-Focus vs. Non-High-Focus). It grounds the geography for a global audience.
3.  **Refine Figure 1 & 7:** These suffer from overlapping text and missing/unclear axes. They need "manual" aesthetic polish to reach AER/QJE standards. High-end journals hate overlapping labels.