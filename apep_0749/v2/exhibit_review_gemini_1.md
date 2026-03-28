# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-28T01:47:22.177108
**Route:** Direct Google API + PDF
**Tokens:** 16837 in / 1843 out
**Response SHA256:** ef60c1c4bcc3ac3e

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics"
**Page:** 9
- **Formatting:** Clean, professional use of horizontal rules (booktabs style). Panel A/B structure is effective for comparing treated and never-treated groups.
- **Clarity:** Excellent. The comparison of pre-treatment means across groups is immediately visible.
- **Storytelling:** Essential. It establishes that treated and control states have nearly identical baseline alcohol-involved crash rates (2.80 vs 2.77), which validates the comparison.
- **Labeling:** Good. Notes clearly define "annualized per 100,000 population."
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Effect of Online Sports Betting on Fatal Crash Rates"
**Page:** 12
- **Formatting:** Standard journal format. Numbers are appropriately rounded.
- **Clarity:** High. Clear distinction between alcohol-involved (effect found) and non-alcohol (placebo null) crashes.
- **Storytelling:** This is the "money table." It provides the headline result and the placebo test in one view.
- **Labeling:** Significance stars and standard error placement are correct. Notes specify the estimator used.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Event-Study Estimates: Dynamic ATT for Alcohol-Involved Fatal Crash Rates"
**Page:** 14
- **Formatting:** Generally clean. The 95% confidence band (shaded) is a good choice for readability compared to many overlapping whiskers.
- **Clarity:** The pre-trend is clearly flat, and the gradual post-treatment increase is visible. However, the y-axis labels could be more frequent (currently only -1, 0, 1).
- **Storytelling:** Crucial for DiD papers to show the absence of pre-trends.
- **Labeling:** The x-axis "Quarters Relative to OSB Legalization" is clear.
- **Recommendation:** **REVISE**
  - Increase the density of y-axis ticks (e.g., every 0.25 units) to make the magnitude of individual coefficients easier to estimate visually.
  - Ensure the dashed horizontal line at 0 is slightly thicker or a different color (like gray) to distinguish it from the grid.

### Table 3: "Game-Day Triple-Difference: Testing the Bar-Attendance Hypothesis"
**Page:** 15
- **Formatting:** Professional. Aligning three different model types (OLS, Poisson, Weekly) in one table is efficient.
- **Clarity:** The main coefficients (all near zero) stand out. 
- **Storytelling:** This is the core of the "revisionist" argument of the paper. It proves the previous version's result was an artifact.
- **Labeling:** Well-labeled. The "Exposure adjustment" row is a vital inclusion given the paper's methodological message.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Game-Day Triple-Difference Coefficients Across Specifications"
**Page:** 16
- **Formatting:** Good use of dot-and-whisker.
- **Clarity:** It successfully visualizes that regardless of the specification, the effect is statistically zero.
- **Storytelling:** Slightly redundant with Table 3, but helps emphasize the "nullness" of the result for a quick-scan reader.
- **Labeling:** "Treated x Game Day Coefficient" on the y-axis is clear.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Temporal Decomposition of the Alcohol-Crash Effect"
**Page:** 17
- **Formatting:** Clean panel structure. 
- **Clarity:** The "Late Night" and "Weekend" results are the only ones with stars, making the "where the effect lives" story very clear.
- **Storytelling:** Moves the paper from "rejecting a mechanism" to "proposing a new pattern." 
- **Labeling:** Hour bins are clearly defined.
- **Recommendation:** **KEEP AS-IS** (Consider merging with Figure 3 for a single "Temporal Patterns" exhibit).

### Figure 3: "Hour-of-Day Decomposition: ATT by Time Window"
**Page:** 18
- **Formatting:** Consistent with Figure 2.
- **Clarity:** Very clear visualization of the late-night spike.
- **Storytelling:** Visualizes Panel A of Table 4. 
- **Recommendation:** **REVISE**
  - **Consolidate:** Top-tier journals often prefer a multi-panel figure. Create Figure 3 with Panel A (Hour of Day) and Panel B (Day of Week). This would replace the need for Table 4 in the main text, moving Table 4 to the appendix for the exact point estimates.

### Table 5: "Robustness of the Baseline Effect"
**Page:** 19
- **Formatting:** Logical grouping of alternative specifications.
- **Clarity:** High. 
- **Storytelling:** Demonstrates that the result isn't driven by COVID or a single influential state (NJ).
- **Labeling:** Notes are comprehensive.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Leave-One-Out Analysis: ATT When Each Treated State Is Dropped"
**Page:** 20
- **Formatting:** Professional.
- **Clarity:** Shows the tight range of estimates.
- **Storytelling:** Essential robustness for staggered DiD with a small number of treated units (18).
- **Recommendation:** **MOVE TO APPENDIX**
  - While helpful, the "Leave-one-out range" is already reported as a single row in Table 5. The visual representation takes up a full page but doesn't change the takeaway. Moving this to the appendix would tighten the main text.

---

## Appendix Exhibits

### Table 6: "State-Level Online Sports Betting Treatment Status"
**Page:** 29
- **Formatting:** Excellent data transparency.
- **Clarity:** Very high. The "In FARS Sample?" column is a clever way to explain the exclusion of 2023/24 legalizers.
- **Recommendation:** **KEEP AS-IS**

### Table 7: "Standardized Effect Sizes"
**Page:** 30
- **Formatting:** Minimalist.
- **Clarity:** Good.
- **Storytelling:** Provides the Cohen's d style "SDE" (0.22).
- **Recommendation:** **REMOVE**
  - This information can be integrated into a single sentence in the results section or a footnote in Table 2. It does not warrant its own appendix page.

---

## Overall Assessment

- **Exhibit count:** 4 main tables, 4 main figures, 2 appendix tables, 0 appendix figures.
- **General quality:** The exhibits are exceptionally high quality, following the "less is more" aesthetic of top-five journals. The use of white space and the absence of vertical gridlines are perfect.
- **Strongest exhibits:** Table 2 (The primary result) and Table 3 (The mechanism rejection).
- **Weakest exhibits:** Figure 1 (needs more y-axis detail) and Table 7 (unnecessary).
- **Missing exhibits:** 
  1. **Raw Data Plot:** A simple plot of the raw alcohol-involved crash rate over time (aggregating all treated vs. all control) is often requested by reviewers to see the "raw" data before the CS-DiD machinery is applied.
  2. **Map of Treatment:** A US map shaded by "Year of OSB Legalization" provides immediate geographic/temporal context for the staggered design.

**Top 3 improvements:**
1. **Consolidate Temporal Analysis:** Merge the "Hour of Day" and "Day of Week" results into a single two-panel figure. This is more "QJE-style" and tells the story of the *nature* of the externality more forcefully than separate tables/figures.
2. **Move Figure 4 to Appendix:** The paper has a lot of exhibits for a relatively straightforward result. Moving the leave-one-out plot to the appendix keeps the main text focused on the "Game Day" rejection.
3. **Enhance Figure 1:** Add more y-axis ticks and consider adding a "number of treated states" count along the x-axis to show how the sample builds over event time.