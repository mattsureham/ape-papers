# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-09T11:01:47.566356
**Route:** Direct Google API + PDF
**Tokens:** 23597 in / 1804 out
**Response SHA256:** ca2220e6d29b96cf

---

This review evaluates the visual exhibits of the paper "The Hidden Offset: Online Sports Betting, Alcohol Consumption, and Fatal Traffic Crashes" against the standards of top-tier economics journals.

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics"
**Page:** 12
- **Formatting:** Clean and professional. Proper use of horizontal rules (booktabs style).
- **Clarity:** Good. It clearly separates counts from rates and provides the necessary panel dimensions (N=459).
- **Storytelling:** Essential. It establishes the "Sunday premium" (22% of crashes) which motivates the entire DDD strategy.
- **Labeling:** Clear. Units (per 100K, millions) are explicitly stated.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Main Results: Effect of Online Sports Betting on Alcohol-Involved Fatal Crashes"
**Page:** 17
- **Formatting:** Excellent. Decimal-aligned coefficients and standard errors. Logical grouping of specifications.
- **Clarity:** High. Using "DDD", "Placebo", and "TWFE" as sub-headers for columns is very helpful for the 10-second parse.
- **Storytelling:** This is the "money table." It puts the aggregate null side-by-side with the mechanism-driven DDD.
- **Labeling:** Standard errors are in parentheses; significance stars are defined. Note is comprehensive.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Mechanism Tests: Season, Time of Day, and COVID Sensitivity"
**Page:** 20
- **Formatting:** Consistent with Table 2.
- **Clarity:** The use of "—" for the triple interaction in columns 1-2 (where it's inestimable) is correct but should be explicitly mentioned in the note to avoid confusion with a "null" result.
- **Storytelling:** Supports the "venue substitution" story by showing the effect disappears in the off-season.
- **Labeling:** Good.
- **Recommendation:** **REVISE**
  - Add a brief sentence to the note: "Triple interaction terms in columns (1) and (2) are omitted as they are collinear with the sample restrictions."

### Table 4: "HonestDiD Sensitivity Bounds ($\Delta^{SD}$)"
**Page:** 24
- **Formatting:** Minimalist.
- **Clarity:** This is a highly technical table. While standard for "new econometrics" papers, for a general interest journal (AER/QJE), this is often better as a figure or moved to the appendix unless the violation of parallel trends is a major concern.
- **Storytelling:** It proves robustness but doesn't "show" the result.
- **Labeling:** "M (Smoothness)" is well-labeled.
- **Recommendation:** **MOVE TO APPENDIX** (The text on page 23 already summarizes the result sufficiently for the main flow).

---

## Appendix Exhibits

### Table 5: "Online Sports Betting Legalization Dates"
**Page:** 35
- **Formatting:** Simple list.
- **Clarity:** Very high. "Months in Sample" is a clever and useful addition for readers to gauge the power of specific state variations.
- **Storytelling:** Provides the raw variation behind the staggered DiD.
- **Recommendation:** **KEEP AS-IS** (Wait—consider promoting to Main Text if space allows, as it's the "first stage" of the identification).

### Figure 1: "Event Study: Alcohol-Involved Crash Rate Relative to Online Betting Legalization"
**Page:** 36
- **Formatting:** Standard `fixest` output style.
- **Clarity:** Good. The "Pre-treatment" and "Post-treatment" labels are helpful.
- **Storytelling:** Essential for validating the DiD. It shows a flat pre-trend and a noisy null post-treatment.
- **Labeling:** Y-axis is clearly labeled with units.
- **Recommendation:** **PROMOTE TO MAIN TEXT** (Top journals almost always require the event study figure in the main results section, usually right after the main table).

### Figure 2: "Trends in Alcohol-Involved Crash Rates: Treated vs. Control States"
**Page:** 37
- **Formatting:** Clean line plot.
- **Clarity:** The vertical dashed lines for the "range of treatment dates" is a bit cluttered. 
- **Storytelling:** Visualizes the "raw" data. 
- **Recommendation:** **REVISE**
  - Use a single dashed line for the *first* treatment (June 2018) and a shaded area for the rollout period rather than two identical dashed lines.

### Figure 3: "Leave-One-Out Sensitivity: DDD Coefficient Dropping Each Treated State"
**Page:** 39
- **Formatting:** Coefficient plot style.
- **Clarity:** Excellent. The "Full sample" dashed line provides an immediate benchmark.
- **Storytelling:** Shows the result is not driven by one large state (like NY or PA).
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Timeline of Online Sports Betting Legalization"
**Page:** 40
- **Formatting:** Gantt-style chart.
- **Clarity:** Very clear way to show the staggered rollout.
- **Storytelling:** Redundant with Table 5, but visually superior.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Day-of-Week Distribution of Alcohol-Involved Fatal Crashes"
**Page:** 41
- **Formatting:** Bar chart.
- **Clarity:** Colors (blue/red) are distinct. 
- **Storytelling:** This is a very strong "descriptive" figure that justifies the Sunday focus.
- **Recommendation:** **PROMOTE TO MAIN TEXT** (Place in the Data/Background section to motivate the DDD).

### Figure 6: "Summary of Mechanism Test Coefficients"
**Page:** 42
- **Formatting:** Summary forest plot.
- **Clarity:** This is the most effective "at-a-glance" exhibit in the paper.
- **Storytelling:** Consolidates all the disparate tests in Tables 2 and 3 into one clear message.
- **Recommendation:** **PROMOTE TO MAIN TEXT** (This should be the concluding figure of the Results section).

### Table 6: "Standardized Effect Sizes for Main Outcomes"
**Page:** 43
- **Formatting:** Technical table.
- **Clarity:** The "Classification" column is slightly subjective/non-standard for Econ.
- **Storytelling:** Helps with interpretation of the "null."
- **Recommendation:** **KEEP AS-IS** (Stay in Appendix).

---

# Overall Assessment

- **Exhibit count:** 4 main tables, 0 main figures (as currently placed), 2 appendix tables, 6 appendix figures.
- **General quality:** The tables are exceptionally well-formatted and AER-ready. The figures are clean but currently hidden in the appendix, which weakens the main text's impact.
- **Strongest exhibits:** Table 2 (Main Results) and Figure 6 (Mechanism Summary).
- **Weakest exhibits:** Figure 2 (cluttered treatment lines) and Table 4 (too dry for main text).
- **Missing exhibits:** A **Map of the US** showing treated vs. control states is a standard "visual " in staggered DiD papers to show geographic balance.

**Top 3 Improvements:**

1.  **Bring the Figures into the Main Text:** A paper without figures in the main text feels like a technical report. Move **Figure 1 (Event Study)**, **Figure 5 (Day-of-Week)**, and **Figure 6 (Mechanism Summary)** into the main body.
2.  **Harmonize Table 2 and Figure 6:** Use the same terminology in both (e.g., ensure "Night alc." in Table 2 matches "Nighttime DDD" in Figure 6).
3.  **Add a Geographic Map:** Create a figure showing which states are "Online," "Retail-Only," and "No Betting" to help readers understand the control group composition at a glance.