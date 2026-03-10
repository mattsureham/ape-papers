# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-10T16:37:48.077041
**Route:** Direct Google API + PDF
**Tokens:** 19957 in / 2172 out
**Response SHA256:** 0a1d30ccc83068b9

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Figure 1: "Cross-State Variation in Agricultural Employment Share, 1940"
**Page:** 8
- **Formatting:** Clean and professional. The use of a horizontal bar chart is superior to a map for comparing 48+ entities. Font sizes are legible.
- **Clarity:** Excellent. The sorting of states by value allows the reader to immediately see the range (5% to 50%) and the national mean.
- **Storytelling:** Strong. It justifies the "Tydings Amendment" instrument by showing the massive variation in the underlying economic structure that drove deferments.
- **Labeling:** Clear x-axis with units. Source note is present.
- **Recommendation:** **KEEP AS-IS**

### Table 1: "Summary Statistics by Cohort Group"
**Page:** 9
- **Formatting:** Standard three-line LaTeX table. Professional. Decimal alignment is generally good, though the "Observations" row should be right-aligned or centered under the columns more precisely.
- **Clarity:** High. Grouping by the three identification cohorts (Draft-Eligible, Control, Placebo) is logical.
- **Storytelling:** Essential. It shows the lifecycle progression (occupational scores starting low for the young and rising).
- **Labeling:** Note is comprehensive. Significance stars aren't applicable here, but standard deviations are correctly identified in parentheses.
- **Recommendation:** **REVISE**
  - Add "N" or "Millions" to the Observations row to make it immediately clear these are counts.
  - Consider adding a "Total" column for the full sample.

### Figure 2: "Occupational Score Trajectories by Cohort Group, 1930–1950"
**Page:** 10
- **Formatting:** Good use of distinct colors and markers.
- **Clarity:** The overlapping lines at 1950 are a bit cluttered. The "WWII Begins" dashed line is a helpful anchor.
- **Storytelling:** This is the "motivation" figure. It shows the steep trajectory of the draft-eligible group.
- **Labeling:** Y-axis label "Mean Occupational Income Score" is clear.
- **Recommendation:** **REVISE**
  - Increase the line weight slightly. 
  - The 95% CIs are mentioned in the notes but are invisible on the plot (likely because the sample size is 9M+ and they are tiny). State "Confidence intervals are smaller than the markers" in the notes if they are not visible.

### Table 2: "Effect of WWII Mobilization Exposure on Post-War Outcomes"
**Page:** 14
- **Formatting:** AER-standard. Clean, no vertical lines.
- **Clarity:** Column headers (1)–(6) are clear. Outcomes are well-labeled.
- **Storytelling:** The "Sign Reversal" between Col (1) and Col (2) is the hook of the paper. This table is the "Conventional Result" table.
- **Labeling:** Comprehensive notes. Standard errors correctly noted.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Pre-Trend and Placebo Tests"
**Page:** 15
- **Formatting:** Consistent with Table 2.
- **Clarity:** The distinction between "Pre-Trend" (1930-40) and "Age Placebo" is the core methodological contribution.
- **Storytelling:** Vital. It proves the instrument was already picking up differential growth before the war.
- **Labeling:** Clear period labeling (1930–1940) in headers.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Pre-Trend vs. Post-Treatment Coefficients"
**Page:** 16
- **Formatting:** Standard coefficient plot.
- **Clarity:** Very high. The contrast in magnitudes is the "10-second message."
- **Storytelling:** This is the paper's "Money Shot." It visualizes why the standard DiD fails.
- **Labeling:** Y-axis label is descriptive.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Cohort-Specific Effects of Mobilization Exposure"
**Page:** 17
- **Formatting:** Professional "Event Study" style. Shaded CI area is clean.
- **Clarity:** The vertical threshold line clearly separates the "Control" from "Treated" cohorts.
- **Storytelling:** Excellent. It shows the effect is a "step function" at the eligibility cutoff, which is a powerful defense against the idea that the instrument is just capturing a linear state-level trend.
- **Labeling:** X-axis (Birth Year) is appropriate.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Heterogeneity in Mobilization Effects by Pre-War Characteristics"
**Page:** 18
- **Formatting:** Logical grouping of columns (Occupation vs. Race vs. Farm).
- **Clarity:** "Q1 (Low)" to "Q5 (High)" labels are helpful.
- **Storytelling:** Shows the effect is pervasive, not driven by a single sub-population.
- **Labeling:** Footnotes explain the quintile construction.
- **Recommendation:** **REVISE**
  - This table is actually a bit redundant with Figure 5 for the Occupation Quintiles. Consider merging the "By Race" and "Farm" results into a separate "Mechanisms" table or appendix.

### Figure 5: "Heterogeneity by Pre-War Occupational Score Quintile"
**Page:** 19
- **Formatting:** Matches Figure 3 for consistency.
- **Clarity:** Points and error bars are clear.
- **Storytelling:** Reinforces the "flat" heterogeneity found in Table 4.
- **Labeling:** Includes Mean OccScore in the x-axis labels—very helpful for context.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Leave-One-Out Sensitivity Analysis"
**Page:** 21
- **Formatting:** Standard "dot-and-whisker" for robustness.
- **Clarity:** Ordered by magnitude, which is best practice.
- **Storytelling:** Proves no single state (like CA or MS) is driving the sign reversal.
- **Labeling:** Clear dashed line for the full-sample estimate.
- **Recommendation:** **MOVE TO APPENDIX** (This is a "check-the-box" robustness exhibit that doesn't advance the narrative once the main result is established).

### Figure 7: "Randomization Inference: Distribution of Permuted Test Statistics"
**Page:** 22
- **Formatting:** Histogram with vertical markers.
- **Clarity:** High. Shows the "true" t-statistic is an extreme outlier.
- **Storytelling:** Standard for top-tier journals (especially QJE) to address cluster-robust SE concerns.
- **Labeling:** "RI p-value = 0" is clearly stated.
- **Recommendation:** **MOVE TO APPENDIX**

### Table 5: "Robustness of Main Results"
**Page:** 23
- **Formatting:** List-style table.
- **Clarity:** Good summary of many different checks (Migration, Stayers, etc.).
- **Storytelling:** Solidifies the "Career Disruption" story by ruling out migration as a confounder.
- **Labeling:** Standard errors and Obs are present.
- **Recommendation:** **KEEP AS-IS**

## Appendix Exhibits

### Table 6: "Standardized Effect Sizes for Main Outcomes"
**Page:** 36
- **Formatting:** Clean, includes a "Classification" column which is rare but helpful for interpretation.
- **Clarity:** High.
- **Storytelling:** Helpful for readers to understand if -0.26 is "big." (It shows it is a "Small negative" effect).
- **Labeling:** The "Research Question/Treatment/Data" block in the notes is excellent for standalone readability.
- **Recommendation:** **PROMOTE TO MAIN TEXT** (Perhaps as a final summary table in the Discussion section to help with the "What do the estimates mean?" narrative).

---

## Overall Assessment

- **Exhibit count:** 4 Main Tables, 7 Main Figures, 1 Appendix Table (plus various appendix text).
- **General quality:** Extremely high. The paper follows the "one-message-per-exhibit" rule very well. The visual consistency across Figures 3, 4, and 5 is excellent.
- **Strongest exhibits:** Figure 3 (The Core Finding) and Figure 4 (Cohort Discontinuity).
- **Weakest exhibits:** Table 4 (contains too much disparate information; could be split or moved).
- **Missing exhibits:** 
    - **A Map:** While Figure 1 is better for ranking, a map of "Mobilization Exposure" helps the reader instantly grasp the geography of the Tydings Amendment (South vs. North).
    - **Balance Table:** A table showing that "Draft Eligible" vs "Control" were balanced on 1930 characteristics *within* high/low mobilization states would be the gold standard for this design.

**Top 3 Improvements:**
1. **Consolidate Robustness:** Move Figure 6 (Leave-one-out) and Figure 7 (Randomization Inference) to the Appendix to "declutter" the results section and keep the focus on the Pre-Trend.
2. **Clarify Figure 2:** The 95% CIs are effectively invisible due to the scale and sample size. Mention this in the note or use a different visualization (e.g., plot the *difference* relative to the 1895 cohort).
3. **Enhance Table 1:** Add a "1930-1940 Change" row to the summary statistics to foreshadow the pre-trend evidence presented later.