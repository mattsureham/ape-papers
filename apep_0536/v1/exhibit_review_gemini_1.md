# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-06T11:28:38.270303
**Route:** Direct Google API + PDF
**Tokens:** 17357 in / 1888 out
**Response SHA256:** 2ad3fbaf6b43933f

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Figure 1: "Staggered FTTH Rollout Across French Departments, 2017–2025"
**Page:** 5
- **Formatting:** Clean and professional. The use of grey for individual units and blue for the mean is standard and effective.
- **Clarity:** High. The "spaghetti plot" clearly shows the variation in timing and intensity of the rollout.
- **Storytelling:** Strong. It immediately validates the "staggered" nature of the DiD design.
- **Labeling:** Good. It includes the national mean and IQR. The red vertical lines for elections are a helpful touch for context.
- **Recommendation:** **KEEP AS-IS**

### Table 1: "Summary Statistics"
**Page:** 10
- **Formatting:** Standard journal layout. Numbers are generally aligned, though standard deviations should be consistently decimal-aligned under the means.
- **Clarity:** Good. Splitting by Pre- and Post-FTTH is essential for understanding the secular rise in the outcome variable.
- **Storytelling:** Sets the stage well. It highlights the sharp increase in anti-system voting (12.8% to 26.5%) which necessitates the within-department FE approach.
- **Labeling:** Clear. Notes explain the sample construction and variable definitions.
- **Recommendation:** **KEEP AS-IS** (Minor: ensure standard deviations in parentheses are decimal-aligned with the means above them).

### Figure 2: "FTTH Coverage by Department, Q2 2022"
**Page:** 11
- **Formatting:** Professional choropleth map. The color scale (Viridis-like) is color-blind friendly.
- **Clarity:** High. Clearly shows the "Paris vs. Rural" divide in rollout.
- **Storytelling:** Important for showing spatial correlation, which the author later addresses as an urbanization confound.
- **Labeling:** Legend is clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Anti-System Vote Trends by FTTH Adoption Speed"
**Page:** 12
- **Formatting:** Good. Standard parallel trends visualization.
- **Clarity:** The overlapping error bars and lines make it slightly cluttered at the peaks.
- **Storytelling:** Crucial. It shows that while the levels differ (Late FTTH has higher anti-system votes), the trends are visually parallel prior to treatment.
- **Labeling:** Clear. 
- **Recommendation:** **REVISE**
  - Slightly offset the "Early" and "Late" markers horizontally (jitter) so the 95% CI bars do not overlap and obscure each other.

### Table 2: "Effect of FTTH Coverage on Political Outcomes"
**Page:** 16
- **Formatting:** Professional. Use of significance stars is standard.
- **Clarity:** Logical progression from main outcome to secondary outcomes.
- **Storytelling:** This is the "hook" of the paper—the negative TWFE coefficient. Column (6) provides the necessary nuance (Presidential vs. European).
- **Labeling:** Notes are comprehensive.
- **Recommendation:** **REVISE**
  - Change "Anti-system (expr.)" to "Anti-system (% valid)" to match the text's terminology (exprimés) more clearly for non-French readers.
  - The "Within R2" is quite low; ensure the text discusses the magnitude of the effect relative to the mean, not just the R2.

### Table 3: "Callaway-Sant’Anna Difference-in-Differences Estimates"
**Page:** 17
- **Formatting:** Standard for CS-DiD reporting.
- **Clarity:** Clear, though it differs significantly from Table 2.
- **Storytelling:** This table provides the "honest" assessment that challenges the TWFE result.
- **Labeling:** 95% CI is provided.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Event Study: FTTH and Anti-System Vote Share (CS-DiD)"
**Page:** 18
- **Formatting:** Clean. Standard event-study plot.
- **Clarity:** The oscillation is very clear, which is the point.
- **Storytelling:** This is the most important "diagnostic" figure. It shows why the reader should be skeptical of the pooled causal effect due to election-cycle noise.
- **Labeling:** Y-axis is clearly labeled.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Robustness Checks"
**Page:** 21
- **Formatting:** Condensed summary table.
- **Clarity:** Very efficient. 
- **Storytelling:** Consolidates multiple robustness checks into one view. The inclusion of the "Placebo: pre-trend" at the bottom is a bold and transparent choice.
- **Labeling:** "Estimate" column should explicitly state these are coefficients from separate regressions.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Leave-One-Department-Out Jackknife"
**Page:** 22
- **Formatting:** Professional dot plot.
- **Clarity:** High. Shows the stability of the coefficient.
- **Storytelling:** Reassures the reader that no single department (e.g., Paris) is driving the result.
- **Labeling:** The department codes (Y-axis) are a bit small but acceptable for a jackknife.
- **Recommendation:** **MOVE TO APPENDIX**
  - While robust, it is a second-order concern compared to the identification challenges. The main text is getting crowded.

### Figure 6: "Balance: Baseline Anti-System Vote Share and FTTH Deployment Speed"
**Page:** 25
- **Formatting:** Professional scatter with regression line and CI.
- **Clarity:** High.
- **Storytelling:** Supports the claim that deployment wasn't targeted based on political leanings.
- **Labeling:** Clearly shows the slope and p-value on the plot.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Balance Tests: Pre-Treatment Characteristics and FTTH Rollout Speed"
**Page:** 26
- **Formatting:** Standard.
- **Clarity:** Clear.
- **Storytelling:** Quantifies Figure 6. Shows the problematic "turnout" correlation.
- **Labeling:** Well-noted.
- **Recommendation:** **REVISE**
  - Consolidate this table with Figure 6 (put the figure as Panel A and the table as Panel B) to save space and link the visual to the statistic.

---

## Appendix Exhibits
*The provided PDF ends with text-based descriptions for Appendix sections A.1–A.3 but contains no visual exhibits (tables/figures) in the appendix. If any exist in a separate file, they should be reviewed.*

---

## Overall Assessment

- **Exhibit count:** 3 main tables, 6 main figures, 0 appendix tables, 0 appendix figures.
- **General quality:** High. The paper uses modern econometrics (Callaway-Sant'Anna) and provides the necessary diagnostics (Event studies, Jackknife, Balance tests) expected by top-tier journals.
- **Strongest exhibits:** Figure 4 (Event Study) and Figure 1 (Rollout). They tell the technical story of the paper’s identification strengths and weaknesses perfectly.
- **Weakest exhibits:** Figure 5 (Jackknife) is standard but takes up a full page of prime real estate for a result that could be summarized in one sentence.
- **Missing exhibits:** 
    1. **Heterogeneity Table:** The text discusses heterogeneity by Urbanization (7.1) and Polarization (7.2) but doesn't provide a table for these interaction models.
    2. **Map of Anti-System Voting:** A map of the *outcome* (2022 Anti-system vote) to pair with Figure 2 (FTTH coverage) would allow the reader to visually inspect the "urban-rural" correlation mentioned in the text.
- **Top 3 improvements:**
  1. **Consolidate Balance Evidence:** Merge Table 5 and Figure 6 into a single exhibit to improve flow.
  2. **Add Heterogeneity Table:** Create a new "Table 6" that formally presents the interaction models described in Section 7.
  3. **Re-prioritize Main Text:** Move Figure 5 (Jackknife) to the appendix to make room for the suggested map of voting or the heterogeneity table. This keeps the main text focused on the primary argument and the identification "puzzle."