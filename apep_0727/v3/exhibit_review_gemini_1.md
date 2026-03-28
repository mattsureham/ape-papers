# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-28T19:30:15.663096
**Route:** Direct Google API + PDF
**Tokens:** 16837 in / 2421 out
**Response SHA256:** 23ed0e29ef585b94

---

This review evaluates the exhibits of the paper "Too Small by Design: How Threshold-Based Climate Policy Shrank the Panels It Subsidized" against the standards of top-tier economics journals (AER, QJE, JPE).

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Policy Regimes at the 10 kWp Threshold"
**Page:** 6
- **Formatting:** Clean and professional. Uses booktabs-style horizontal lines.
- **Clarity:** Excellent. It provides the essential "roadmap" for the reader to understand the natural experiment.
- **Storytelling:** Vital. It defines the "FIT kink" vs "Surcharge notch" distinction which is the core of the identification.
- **Labeling:** Clear. 
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Summary Statistics: Rooftop Solar Installations by Policy Period"
**Page:** 9
- **Formatting:** Good, but the "N" column needs comma separators for thousands (e.g., 557,638).
- **Clarity:** High.
- **Storytelling:** Important for showing the scale of the data (3M+ obs). However, "Mean Modules" drops significantly in the post-reform period (73.2 to 26.7)—this is a huge shift that deserves a brief mention in the note if it's due to efficiency gains.
- **Labeling:** Suggest adding "kWp" units to the "Mean/Median Cap." headers to avoid redundancy in the rows.
- **Recommendation:** **REVISE**
  - Add comma separators to the $N$ column.
  - Right-align all numeric columns to ensure decimal points (even implicit ones) line up.

### Table 3: "Bunching Estimates at the 10 kWp Threshold by Policy Period"
**Page:** 13
- **Formatting:** Professional.
- **Clarity:** The "Surcharge - Pre-FIT" row is the key DiB estimate. It should be separated by a partial horizontal rule to distinguish it from the individual period estimates.
- **Storytelling:** This is the "Money Table." It proves the central thesis.
- **Labeling:** $\hat{b}$ is standard but should be defined in the note (as it is).
- **Recommendation:** **REVISE**
  - Add a `\midrule` or `\cmidrule` above the "Surcharge - Pre-FIT" row to indicate it is a derived result/difference.

### Table 4: "Annual Bunching Ratios at 10 kWp, 2008–2024"
**Page:** 14
- **Formatting:** Very long.
- **Clarity:** This table is essentially a "data dump" of Figure 2.
- **Storytelling:** While precise, it is difficult to digest. The 95% CI is better visualized than read in a table of 17 rows.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**
  - Figure 2 does the storytelling work here. The exact coefficients are secondary for the main text flow.

### Figure 1: "Density of Rooftop Solar Installations Near 10 kWp: Four Policy Periods"
**Page:** 15
- **Formatting:** Modern. The "10 kWp threshold" dashed line is helpful.
- **Clarity:** A bit "spaghetti-like" because four lines overlap. 
- **Storytelling:** Shows the "missing middle" for the surcharge period clearly.
- **Labeling:** Y-axis is "Share of Installations"—ensure this is consistent with "Density."
- **Recommendation:** **REVISE**
  - Increase line weight for the "Surcharge" line to make it the clear focal point.
  - Consider a grayscale version or more high-contrast colors; the blue and teal are very similar.

### Figure 2: "Annual Bunching Ratio at 10 kWp, 2008–2024"
**Page:** 16
- **Formatting:** Excellent. The color-coding by regime is effective.
- **Clarity:** Very high. The "step-function" is immediate.
- **Storytelling:** This is the most important figure in the paper.
- **Labeling:** Axis labels are clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Monthly Bunching Ratio at 10 kWp, 2013–2024"
**Page:** 17
- **Formatting:** Line plot is appropriate for high-frequency data.
- **Clarity:** The "Surcharge abolished" label overlaps with a data spike.
- **Storytelling:** Vital for showing the *speed* of adjustment (immediate for notch, gradual for threshold expansion).
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - Move the text labels for the vertical lines (e.g., "Surcharge abolished") slightly to the left or right so they don't obscure the line plot.

### Figure 4: "Observed vs. Counterfactual Density: Surcharge Period (2014–2020)"
**Page:** 18
- **Formatting:** Standard Kleven-style bunching plot.
- **Clarity:** High.
- **Storytelling:** Essential "proof of concept" for the bunching methodology.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Module Count Distribution: Systems Near 10 kWp (2014–2020)"
**Page:** 19
- **Formatting:** Histogram.
- **Clarity:** The "At/Above 10 kWp" (blue) is almost invisible because there are so few observations.
- **Storytelling:** Crucial for the "physical downsizing" vs "reporting" argument. 
- **Labeling:** Good.
- **Recommendation:** **REVISE**
  - Use a log scale for the Y-axis OR add a call-out/inset for the "At/Above 10 kWp" group. Because the policy was so effective, the "Above" group is too small to see on a linear scale, which ironically makes the comparison hard to visualize.

### Figure 6: "Installation Type Placebo: Rooftop vs. Ground-Mount (2014–2020)"
**Page:** 20
- **Formatting:** Consistent with Figure 1.
- **Clarity:** Good.
- **Storytelling:** Standard placebo check.
- **Labeling:** Good.
- **Recommendation:** **MOVE TO APPENDIX**
  - The text mentions the sample size is very small (N=325). Keeping it in the main text might draw too much scrutiny to a weak (though supportive) placebo.

### Figure 7: "Bunching Ratio by Federal State (2014–2020)"
**Page:** 21
- **Formatting:** Dot plot (Lollipop chart). Excellent choice.
- **Clarity:** Very high. Shows uniformity.
- **Storytelling:** Supports the "expert intermediary" theory (national market).
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Mechanism Evidence: Kink–Notch Decomposition and Module Counts"
**Page:** 22
- **Formatting:** Uses Panels A and B effectively.
- **Clarity:** Panel B is quite long.
- **Storytelling:** Panel A is a bit redundant with Table 3 and Figure 2. Panel B is better served by Figure 5.
- **Recommendation:** **REMOVE**
  - Consolidate the "Kink vs Notch" contribution numbers into the text or a small note in Table 3. The raw counts in Panel B are already visualized in Figure 5.

### Table 6: "Bunching Magnitudes Across Settings"
**Page:** 23
- **Formatting:** Professional.
- **Clarity:** High.
- **Storytelling:** Powerful "External Validity" table. It justifies why this paper is an AER-level contribution (the effect is 10x larger than the literature).
- **Recommendation:** **KEEP AS-IS** (Consider promoting this to an earlier position in the results section).

### Figure 8: "Density of Rooftop Solar Installations Near 30 kWp: Four Policy Periods"
**Page:** 24
- **Formatting:** Consistent.
- **Clarity:** Messy due to the pre-existing FIT kink at 30.
- **Storytelling:** It's "Supplementary Evidence" (as per the heading).
- **Recommendation:** **MOVE TO APPENDIX**

### Table 7: "Robustness: Polynomial Degree and Placebo Tests"
**Page:** 26
- **Formatting:** Good.
- **Clarity:** High.
- **Storytelling:** Standard robustness.
- **Recommendation:** **MOVE TO APPENDIX**

---

## Appendix Exhibits

### Table 8: "Standardized Effect Sizes"
**Page:** 30
- **Formatting:** Empty "SD" and "SDE" columns (containing only dashes).
- **Recommendation:** **REMOVE**
  - If the data doesn't exist or isn't applicable, don't include a table of empty columns. This information is better suited for a single sentence in the text.

### Table 9: "Additional Robustness: Exclusion Windows and 7 kWp Placebo"
**Page:** 30
- **Formatting:** Good.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 6 tables main, 8 figures main, 2 tables appendix, 0 figures appendix.
- **General quality:** Extremely high. The figures are modern and "clean," avoiding the dated Look of Stata-default graphics.
- **Strongest exhibits:** Figure 2 (Annual Bunching) and Table 6 (Comparison with Literature).
- **Weakest exhibits:** Table 5 (Redundant) and Table 8 (Empty).
- **Missing exhibits:** A **Map of Germany** showing bunching intensity by state (instead of just the dot plot in Figure 7) would be very "AER-style." Also, a **Conceptual Diagram** showing the Budget Constraint with a Kink vs. a Notch would help non-public-econ readers.

### Top 3 Improvements:
1. **Aggressive Consolidation:** Move Tables 4, 7 and Figures 6, 8 to the Appendix. The main text is currently "cluttered" with robustness and placebo checks that interrupt the very strong narrative arc.
2. **Visual Contrast in Figure 5:** The "Above Threshold" count is the most important comparison for the "reporting bias" argument. Use an inset or a different scale to make that tiny blue bar visible.
3. **Add a Theory Sketch:** A simple Figure 0 showing a budget constraint (Capacity vs. NPV) with a notch would make the "Dominated Region" intuition immediate for the reader.