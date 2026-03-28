# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-28T16:40:52.899207
**Route:** Direct Google API + PDF
**Tokens:** 16837 in / 2017 out
**Response SHA256:** 9b00ca26266f2fa1

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Policy Regimes at the 10 kWp Threshold"
**Page:** 5
- **Formatting:** Professional and clean. Uses booktabs-style horizontal lines.
- **Clarity:** Excellent. It provides a necessary roadmap for the "four-break" design mentioned in the abstract.
- **Storytelling:** Essential. It translates complex regulatory dates into the "Kink" vs. "Notch" vocabulary used later.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Summary Statistics: Rooftop Solar Installations by Policy Period"
**Page:** 9
- **Formatting:** Standard journal format. Numbers are well-aligned.
- **Clarity:** Good. It shows the massive shift in "Mean Modules" which hints at the mechanism.
- **Storytelling:** Important for showing the scale of the data (3M+ observations). 
- **Labeling:** Note clearly defines the sample restrictions.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Bunching Estimates at the 10 kWp Threshold by Policy Period"
**Page:** 12
- **Formatting:** Professional. Uses Panels A and B effectively to separate levels from differences.
- **Clarity:** High. The $\hat{b}$ column is the "money" column and is easy to find.
- **Storytelling:** This is the core empirical result of the paper.
- **Labeling:** Bootstrap replications and exclusion windows are correctly noted.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Annual Bunching Ratios at 10 kWp, 2008–2024"
**Page:** 13
- **Formatting:** Clean, but very long. 17 rows of annual data.
- **Clarity:** It is a lot of raw numbers. The reader's eye struggles to see the "step function" here compared to a figure.
- **Storytelling:** Redundant with Figure 2. While the raw counts ($N_{9.9}$, $N_{10.1}$) are interesting, they could be moved to an appendix or a footnote.
- **Labeling:** Good.
- **Recommendation:** **MOVE TO APPENDIX** — Figure 2 tells this story much more effectively for the main text.

### Figure 1: "Density of Rooftop Solar Installations Near 10 kWp: Four Policy Periods"
**Page:** 14
- **Formatting:** Modern and clean. The color palette is distinguishable.
- **Clarity:** A bit cluttered. Overlaying four different distributions makes it hard to see the "Pre-FIT" baseline clearly.
- **Storytelling:** Crucial "raw data" figure. It proves the spike isn't an artifact of the estimator.
- **Labeling:** Y-axis is clearly labeled "Share of Installations".
- **Recommendation:** **REVISE** 
  - Increase the line weight for the "Surcharge" line to make it pop.
  - Consider a small "zoom" inset or a separate panel for the Pre-FIT line if it's getting lost at the bottom.

### Figure 2: "Annual Bunching Ratio at 10 kWp, 2008–2024"
**Page:** 15
- **Formatting:** Excellent. Color-coding bars by policy regime is a very effective QJE/AER-style move.
- **Clarity:** Extremely high. The "step-function" argument is proven here in 5 seconds.
- **Storytelling:** This is the most important figure in the paper.
- **Labeling:** Legend and axis labels are clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Observed vs. Counterfactual Density: Surcharge Period (2014–2020)"
**Page:** 16
- **Formatting:** Standard bunching plot. Shaded area for excess mass is helpful.
- **Clarity:** High.
- **Storytelling:** Provides the visual "proof" for the $\hat{b}=86.5$ estimate in Table 3.
- **Labeling:** Clearly shows the exclusion window and polynomial degree.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Module Count Distribution: Systems Near 10 kWp (2014–2020)"
**Page:** 17
- **Formatting:** Clean bar chart.
- **Clarity:** The distinction between "At/Above" and "Below" 10kWp using color is very smart.
- **Storytelling:** Essential for the "Mechanism" section. It proves people are dropping panels, not just misreporting capacity.
- **Labeling:** X-axis units (Number of Modules) are clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Installation Type Placebo: Rooftop vs. Ground-Mount (2014–2020)"
**Page:** 18
- **Formatting:** Consistent with Figure 1.
- **Clarity:** The Ground-mount line is quite "noisy" due to low N (as acknowledged in text).
- **Storytelling:** A classic placebo check.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS** (or move to Appendix if space is tight, but it's strong evidence).

### Figure 6: "Bunching Ratio by Federal State (2014–2020)"
**Page:** 19
- **Formatting:** Dot plot/Cleveland plot. Much better than a map for this purpose.
- **Clarity:** Excellent. Shows the uniformity of the effect.
- **Storytelling:** Supports the "national market/professional installers" argument.
- **Labeling:** States are clearly listed.
- **Recommendation:** **KEEP AS-IS**

## Appendix Exhibits

### Figure 7: "Density of Rooftop Solar Installations Near 30 kWp: Four Policy Periods"
**Page:** 22
- **Formatting:** Consistent with Figure 1.
- **Clarity:** Very "spiky" and busy.
- **Storytelling:** This is the "extension" to the 2021 reform. 
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS** (Correctly placed in the "Robustness/Discussion" section).

### Table 5: "Mechanism Evidence: Kink–Notch Decomposition and Module Counts"
**Page:** 28
- **Formatting:** Good use of panels. 
- **Clarity:** Panel B is essentially the data behind Figure 4. 
- **Storytelling:** Strong.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Bunching Magnitudes Across Settings"
**Page:** 29
- **Formatting:** Simple and effective.
- **Clarity:** High.
- **Storytelling:** This table is the "hook" for the Discussion. It justifies the paper's existence by showing the effect is 10x larger than the literature.
- **Recommendation:** **PROMOTE TO MAIN TEXT** — This belongs in the Introduction or the very start of the Results to set the stakes.

### Table 7: "Robustness: Polynomial Degree, Exclusion Window, and Placebo Tests"
**Page:** 30
- **Formatting:** Dense but logical.
- **Clarity:** Panel C (Placebo Thresholds) is very effective.
- **Storytelling:** Standard robustness table.
- **Recommendation:** **KEEP AS-IS**

### Table 8: "Standardized Effect Sizes"
**Page:** 30
- **Formatting:** Professional.
- **Clarity:** High.
- **Storytelling:** Good for a concluding "summary of magnitudes."
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 3 main tables, 6 main figures, 5 appendix tables, 1 appendix figure.
- **General quality:** Extremely high. The paper follows the modern "Visual First" empirical style. Figures 2 and 4 are particularly strong.
- **Strongest exhibits:** Figure 2 (Annual Bunching) and Figure 4 (Module Counts).
- **Weakest exhibits:** Table 4 (too much raw data) and Figure 1 (a bit cluttered).
- **Missing exhibits:** A **"Conceptual/Theory" Figure** showing a budget set with a kink vs. a notch would be very helpful in Section 2 to help readers visualize the "dominated region" mentioned in the text.

**Top 3 improvements:**
1. **Move Table 6 (Comparison with Literature) to the Main Text.** This is a high-impact "selling" table that should be visible early on.
2. **Move Table 4 (Annual raw counts) to the Appendix.** It slows down the reader and Figure 2 already provides the intuition.
3. **Add a Theory Sketch.** A simple 2D plot of "Self-Consumption Benefit vs. System Size" showing the $10kWp$ notch would make Section 2.3 much more accessible to non-experts.