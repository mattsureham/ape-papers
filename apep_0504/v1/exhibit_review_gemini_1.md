# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-04T15:21:40.336041
**Route:** Direct Google API + PDF
**Tokens:** 18917 in / 2070 out
**Response SHA256:** a97e57620835a432

---

# Exhibit-by-Exhibit Review

I have reviewed the tables and figures in the paper titled **"Does Naming Work? Mandatory Food Hygiene Rating Display and Food Market Structure in the United Kingdom."** The paper utilizes a triple-difference design and staggered DiD to evaluate the impact of mandatory rating displays. Below is the detailed feedback for each exhibit.

---

## Main Text Exhibits

### Table 1: "Pre-Treatment Summary Statistics (2008Q1–2013Q3)"
**Page:** 10
- **Formatting:** Clean and professional. Uses appropriate spacing.
- **Clarity:** High. Provides a clear snapshot of the baseline differences between the three nations.
- **Storytelling:** Essential for justifying the parallel trends assumption and showing the scale of the "never-treated" English control group.
- **Labeling:** Clear. Note includes the period and unit of observation.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Effect of Mandatory Food Hygiene Rating Display on Food Business Dynamics"
**Page:** 13
- **Formatting:** Standard professional layout. Numbers are decimal-aligned.
- **Clarity:** Good, but the variable names (e.g., `n_entry`, `time_id`) are slightly "code-like."
- **Storytelling:** This is the "naive" DiD table. It sets up the puzzle: why is there a large negative effect on entry? It effectively prepares the reader for the DDD results.
- **Labeling:** Significance stars and SE notation are correct.
- **Recommendation:** **REVISE**
  - Rename dependent variables to "Entries (Level)", "Entry Rate", "Exit Proxy", and "Net Survivors" to avoid using programming variable names in the header.

### Table 3: "Triple-Difference: Food vs. Non-Food Businesses"
**Page:** 15
- **Formatting:** Good. Logical ordering of coefficients.
- **Clarity:** The core message (positive interaction) is prominent.
- **Storytelling:** This is the most important table in the paper. It resolves the "deterrence" puzzle found in Table 2.
- **Labeling:** The note correctly explains the interpretation of the coefficients.
- **Recommendation:** **KEEP AS-IS** (Top journal-ready).

### Figure 1: "Event Study: Effect on Food Business Entries"
**Page:** 16
- **Formatting:** Modern and clean. Gray gridlines are subtle.
- **Clarity:** Excellent. The point estimates and CIs are clearly distinguishable. 
- **Storytelling:** Crucial for verifying pre-trends. It shows the gradual decline that the paper later explains as a country-level trend.
- **Labeling:** Axis labels are clear. Units (Quarters) are appropriate.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Event Study: Effect on Cohort Exit Proxy"
**Page:** 17
- **Formatting:** Consistent with Figure 1.
- **Clarity:** Clear, though the "noisy" nature of the data is apparent.
- **Storytelling:** Supports the discussion on entrant quality, though the author correctly notes its limitations.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Callaway & Sant’Anna: Dynamic Effects on Food Business Entries"
**Page:** 18
- **Formatting:** Professional for this specific estimator.
- **Clarity:** **Low.** The x-axis labels are overlapping and unreadable because there are too many periods.
- **Storytelling:** Robustness check for staggered timing.
- **Labeling:** Legend is clear, but axis tick marks are a mess.
- **Recommendation:** **REVISE**
  - Thin out the x-axis labels. Instead of labeling every quarter (e.g., -35.12...), label every 4 or 8 quarters (-32, -24, -16...). Remove the excessive decimal places on the x-axis labels.

### Figure 4: "Food Hygiene Rating Distribution by Country (2026)"
**Page:** 19
- **Formatting:** Grouped bar chart is standard. Colors (Gray, Orange, Red) are distinct.
- **Clarity:** High. One can immediately see the rightward shift in Northern Ireland.
- **Storytelling:** Provides the cross-sectional "long-run" evidence of quality.
- **Labeling:** Y-axis is properly labeled as percentage points.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Food Hygiene Rating Quality by Country (Current Snapshot)"
**Page:** 19
- **Formatting:** Minimalist and professional.
- **Clarity:** Summarizes Figure 4 effectively.
- **Storytelling:** Could potentially be merged with Table 1 as a "Comparison Table" (Pre vs. Post), but works well here to anchor Section 6.6.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Placebo Test: Food vs. Non-Food Businesses"
**Page:** 20
- **Formatting:** Consistent with earlier tables.
- **Clarity:** Comparison between columns 1/2 and 3/4 is immediate.
- **Storytelling:** Demonstrates that the "decline" is a macro trend.
- **Labeling:** Professional.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Placebo Test: Food vs. Non-Food Business Entry Trends"
**Page:** 22
- **Formatting:** Multiple line plot.
- **Clarity:** Slightly cluttered. Four lines + a vertical dashed line makes it harder to parse the "10-second message."
- **Storytelling:** Vital for the placebo argument.
- **Labeling:** Legend is clear.
- **Recommendation:** **REVISE**
  - Increase line thickness for the "Food" lines and use a different line style (e.g., dashed vs. solid) to more clearly distinguish Food from Non-food, rather than just relying on color and lightness.

### Table 6: "Robustness: Food Business Entries Under Alternative Specifications"
**Page:** 22
- **Formatting:** Good use of column headers to denote samples.
- **Clarity:** High. Shows stability of the negative raw DiD across cuts.
- **Storytelling:** Standard robustness table.
- **Labeling:** Significance levels are clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Food Business Survival Rate by Incorporation Cohort"
**Page:** 25
- **Formatting:** Good use of markers.
- **Clarity:** The "dip" in 2018 is very visible.
- **Storytelling:** Addresses the "entrant quality" mechanism.
- **Labeling:** Vertical lines are well-labeled in the note.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Figure 7: "Raw Trends in Food Business Dynamics by Country"
**Page:** 34
- **Formatting:** High quality.
- **Clarity:** Very high. This is actually more intuitive than Figure 5.
- **Storytelling:** Essential for showing the raw data before FE and controls are applied.
- **Labeling:** Annotated vertical lines are very helpful.
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - This figure is more foundational than Figure 5. It should appear early in the results section (Section 6) to show the reader the raw "upward" trend in the UK that the DiD (which is relative) interprets as a "decline."

### Figure 8: "Local Authorities by Country and Treatment Status"
**Page:** 34
- **Formatting:** Simple bar chart.
- **Clarity:** High.
- **Storytelling:** Redundant with Table 1 (which lists N LAs). 
- **Labeling:** Clear.
- **Recommendation:** **REMOVE**
  - This information is already clearly presented in the "N LAs" column of Table 1. A figure for three data points is not a good use of space.

---

## Overall Assessment

- **Exhibit count:** 5 Main Tables, 5 Main Figures, 1 Appendix Table (Table 6 is in main but serves robustness), 2 Appendix Figures.
- **General quality:** Extremely high. The exhibits follow the "less is more" aesthetic of the QJE/AER. Tables are clean, and figures avoid unnecessary "chart junk."
- **Strongest exhibits:** Table 3 (The DDD results) and Figure 1 (The Event Study).
- **Weakest exhibits:** Figure 3 (X-axis unreadable) and Figure 8 (Redundant).
- **Missing exhibits:** 
    - **A Map:** A map of the UK showing the Local Authorities colored by treatment status (Wales, NI, England) and highlighting the "Border Design" LAs mentioned in Section 7.3. This is standard for papers using geographic variation.
- **Top 3 improvements:**
  1. **Fix Figure 3 X-Axis:** Make the temporal labels readable and remove the decimal places from the periods.
  2. **Promote Figure 7:** Bring the raw trends into the main text to provide context for the negative DiD coefficients.
  3. **Add a Geographic Map:** Visualize the treatment variation across the 300+ Local Authorities to ground the reader in the UK geography.