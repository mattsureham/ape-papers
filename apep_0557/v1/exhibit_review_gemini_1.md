# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-09T17:11:32.750007
**Route:** Direct Google API + PDF
**Tokens:** 18397 in / 2405 out
**Response SHA256:** 76d90ac5bdd63f32

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics"
**Page:** 8
- **Formatting:** Clean, standard "booktabs" style. However, the alignment of numbers is not decimal-aligned, making the SD and Mean columns slightly harder to compare.
- **Clarity:** High. Includes all relevant variables (outcomes, treatment, shock).
- **Storytelling:** Essential. Establishes the skewness of conflict data which justifies the log transformation mentioned in the text.
- **Labeling:** Clear labels. Units (monthly) and currency ($/bbl) are included.
- **Recommendation:** **REVISE**
  - Decimal-align the numbers in all numeric columns.
  - Add a note explaining that N=7992 represents 37 states over 216 months.

### Table 2: "Top 15 States by Geocoded Aid Exposure (as of December 2007)"
**Page:** 9
- **Formatting:** Consistent with Table 1.
- **Clarity:** Good. It quickly identifies the "heavy hitters" in the data.
- **Storytelling:** Very important for the "Boko Haram confound" argument. It shows Borno has high fatalities but moderate aid, supporting the exclusion restriction.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Main DiD Results: Aid Exposure and Conflict"
**Page:** 12
- **Formatting:** Journal-ready. Standard error parentheses and FE indicators are clear.
- **Clarity:** Excellent. The progression from continuous to binary to controls is logical.
- **Storytelling:** This is the "money table." It clearly shows the null result across specifications. 
- **Labeling:** Significance stars are well-defined.
- **Recommendation:** **REVISE**
  - The dependent variable is missing from the table header. Add "Dependent Variable: log(Conflict Events + 1)" at the top.
  - In the notes, explicitly state that "RI $p$-value" for the main estimate is 0.207, as it's a key part of the paper's "null" story but only appears in the text.

### Figure 1: "Main DiD Coefficient Estimates Across Specifications"
**Page:** 13
- **Formatting:** Professional "coefplot" style. Clean background.
- **Clarity:** High. Allows for instant comparison of coefficients.
- **Storytelling:** Redundant with Table 3. In top journals, one of these usually goes to the appendix unless the coefficients are too numerous to parse in a table.
- **Labeling:** Clear. 
- **Recommendation:** **MOVE TO APPENDIX**
  - While visually nice, it doesn't add new information beyond Table 3. Moving it preserves main-text "real estate."

### Figure 2: "Event Study: Dynamic Effects of Aid Exposure Around the Oil Shock"
**Page:** 14
- **Formatting:** Excellent. The "Oil crisis begins" annotation is helpful. Shaded 95% CIs are standard.
- **Clarity:** High. The zero line is clear.
- **Storytelling:** Crucial for DiD identification. It proves the "Parallel Trends" assumption.
- **Labeling:** Y-axis label is a bit technical ($\beta_t$ (Log Aid $\times$ Month Indicator)). 
- **Recommendation:** **KEEP AS-IS** (Consider simplifying the y-axis label to "Estimated Effect on log(Conflict)").

### Table 4: "Outcome Heterogeneity: Aid Exposure and Conflict Types"
**Page:** 15
- **Formatting:** Consistent.
- **Clarity:** Good.
- **Storytelling:** Shows the result isn't driven by one specific type of violence.
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - **Consolidate:** Merge this with Figure 3. Having both the table and the figure for the exact same four coefficients is redundant for a main text. Keep the table, move the figure to appendix.

### Figure 3: "Outcome Heterogeneity: Aid Exposure Effects by Conflict Type"
**Page:** 15
- **Formatting:** Professional.
- **Clarity:** High.
- **Storytelling:** Redundant with Table 4.
- **Labeling:** Clear.
- **Recommendation:** **REMOVE** (or move to Appendix). The table is more precise for these few coefficients.

### Table 5: "Sector Heterogeneity: Aid Type and Post-Shock Conflict"
**Page:** 16
- **Formatting:** Good.
- **Clarity:** Clear distinction between Health and Governance.
- **Storytelling:** Important nuance regarding the "Health aid" finding which suggests a geographic confound.
- **Labeling:** Notes are comprehensive.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Randomization Inference: Permutation Distribution of the DiD Coefficient"
**Page:** 17
- **Formatting:** Clean histogram.
- **Clarity:** The vertical red line for the "Actual" estimate makes the p-value intuitive.
- **Storytelling:** Strongest evidence for the "null" result in a small-N (37 clusters) setting.
- **Labeling:** High quality.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Placebo Shock Tests (Non-Event Dates)"
**Page:** 18
- **Formatting:** Clean.
- **Clarity:** Logical columns.
- **Storytelling:** Supports identification.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**
  - This is a standard robustness check that is often summarized in one sentence in the main text.

### Figure 5: "Leave-One-Out Sensitivity: Main Coefficient When Each State Is Dropped"
**Page:** 19
- **Formatting:** Clean.
- **Clarity:** Extremely high. Shows the influence (or lack thereof) of Borno/Plateau.
- **Storytelling:** Addresses the biggest threat to validity (Boko Haram/Borno) visually.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS** (This is a "QJE-style" robustness figure).

### Table 7: "Robustness Checks"
**Page:** 20
- **Formatting:** Clean.
- **Clarity:** High.
- **Storytelling:** Essential. The Poisson PPML result is particularly important for count data.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 8: "Sensitivity to Alternative Shock Dates"
**Page:** 20
- **Formatting:** Consistent.
- **Clarity:** Clear.
- **Storytelling:** Secondary robustness.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**

### Table 9: "Oil State Triple Difference"
**Page:** 21
- **Formatting:** Standard.
- **Clarity:** Clear.
- **Storytelling:** Addresses a logical follow-up question (do oil states react differently?).
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Parallel Trends: Average Conflict in High- versus Low-Aid States"
**Page:** 22
- **Formatting:** Good use of dashed/solid lines.
- **Clarity:** High.
- **Storytelling:** Visual raw-data version of the event study.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 7: "Nigeria: Oil Prices and Armed Conflict Events, 1997–2014"
**Page:** 23
- **Formatting:** Dual y-axis is usually discouraged in top journals, but works here for context.
- **Clarity:** Busy but readable.
- **Storytelling:** Vital "Big Picture" figure. It shows the shock and the outcome trend.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS** (Move to Section 2 or 3 as an "Introductory Figure").

### Figure 8: "Geographic Distribution of Foreign Aid in Nigeria"
**Page:** 24
- **Formatting:** Clean bar chart.
- **Clarity:** High.
- **Storytelling:** Shows the cross-sectional variation in treatment.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Figure 9: "Placebo and Alternative Shock Date Coefficients"
**Page:** 32
- **Formatting:** Professional.
- **Clarity:** High.
- **Storytelling:** Effectively consolidates Table 6 and Table 8. 
- **Recommendation:** **KEEP AS-IS** (Note: Since this exists, Table 6 and 8 *definitely* belong in the appendix).

### Table 10: "Standardized Effect Sizes for Main Outcomes"
**Page:** 33
- **Formatting:** Very wordy for a table.
- **Clarity:** Low. The "Important" note and "Research Question" belong in text or a dedicated Appendix note, not inside a table frame.
- **Storytelling:** Good for meta-analysis/comparison.
- **Recommendation:** **REVISE**
  - Move the text-heavy "Notes" section below the table. 
  - Remove the "Research question" and "Method" from the table notes; the appendix reader already knows this.

---

## Overall Assessment

- **Exhibit count:** 8 main tables, 8 main figures, 1 appendix table, 1 appendix figure.
- **General quality:** Extremely high. The paper follows the visual style of modern empirical development economics (e.g., AEJ: Applied or Policy). 
- **Strongest exhibits:** Figure 2 (Event Study), Figure 5 (Leave-one-out), Figure 7 (Context).
- **Weakest exhibits:** Table 10 (Too much text), Figure 3 (Redundant with Table 4).
- **Missing exhibits:** A **Map of Nigeria** showing the intensity of aid exposure and conflict locations. For a geocoded paper in a top journal (QJE/AER), a map is almost mandatory to show the spatial variation described in the text.

**Top 3 improvements:**
1.  **Reduce Redundancy:** Move the "visual versions" of results (Fig 1 and Fig 3) to the appendix if the tables (Tab 3 and Tab 4) are staying in the main text.
2.  **Add a Spatial Map:** Create a Figure 0/1 showing a map of Nigeria with states colored by aid exposure and dots for UCDP conflict events.
3.  **Streamline Robustness:** Move the smaller robustness tables (Tab 6 and Tab 8) to the appendix, as Figure 9 already summarizes their findings effectively for the reader.