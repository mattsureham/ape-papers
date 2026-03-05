# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-05T11:58:34.394107
**Route:** Direct Google API + PDF
**Tokens:** 17877 in / 1754 out
**Response SHA256:** 53622ec6738106ab

---

This review evaluates the visual exhibits of the paper "The Price of Pork: France’s Dual-Mandate Ban and the Fiscal Cost of Local–National Connections" against the standards of top-tier economics journals.

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics by Treatment Group (Pre-Period 2008–2016)"
**Page:** 11
- **Formatting:** Generally clean. However, the horizontal lines (booktabs style) are missing a bottom-terminating line. The indentation of "Constituencies" is inconsistent with the fiscal variables.
- **Clarity:** Excellent. The comparison of Means, Diffs, and p-values allows for a quick assessment of balance.
- **Storytelling:** Essential. It establishes that while there is some imbalance in OpEx/Revenue, the primary outcome (Investment) is balanced.
- **Labeling:** "PC" is defined in the notes, but it would be cleaner to use "Investment (per capita)" in the stub. Units (thousands of euros) should be explicitly in a sub-header or the variable name, not just the notes.
- **Recommendation:** **REVISE**
  - Add a bottom horizontal line.
  - Include units (e.g., "€1k/capita") directly in the variable column to reduce cognitive load.

### Table 2: "Effect of the Dual-Mandate Ban on Commune Fiscal Outcomes"
**Page:** 15
- **Formatting:** High quality. The use of `fixest` style output is standard.
- **Clarity:** The table is wide (7 columns). While readable, Column 7 (Log Invest) feels isolated from the per-capita levels. 
- **Storytelling:** This is the "money" table. The consistent nulls across all columns are the core finding.
- **Labeling:** Significance stars are well-defined. "Clustered (Constituency) standard-errors" has a small typo (hyphen unnecessary).
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Event Study: Investment Per Capita"
**Page:** 17
- **Formatting:** Good use of transparency for CIs. The red dashed line for "Ban effective" is clear.
- **Clarity:** Very clean. The message of "flat pre-trend, null post-trend" is immediate.
- **Storytelling:** This is the most important figure in the paper. It validates the DiD design.
- **Labeling:** The Y-axis label "thousands of euros" is clear. The X-axis "Years relative to ban" is standard.
- **Recommendation:** **REVISE**
  - The "Ban effective" text is slightly crowded by the CI. Move the text label a bit higher or use an arrow.
  - Increase the font size of the axis tick labels for better legibility in print.

### Figure 2: "Event Studies: Four Fiscal Outcomes"
**Page:** 18
- **Formatting:** Professional 2x2 grid. Consistent Y-axis scaling within panels.
- **Clarity:** A bit cluttered. The Y-axis labels "Thousands of euros per capita" are repeated by the shared axis label, but the scales vary significantly (Investment goes to 0.02, State Grants to 0.01).
- **Storytelling:** Excellent. It shows the null result is not unique to one investment measure.
- **Labeling:** The shared Y-axis label is good, but ensure the individual panel titles (Equipment, Investment, etc.) are bolded to stand out more.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Raw Trends in Fiscal Outcomes by Treatment Group"
**Page:** 19
- **Formatting:** Solid lines vs. dashed lines are distinguishable.
- **Clarity:** The "State Grants" panel shows a very tight overlap, which is great for the argument but makes the lines hard to distinguish.
- **Storytelling:** Crucial for transparency. It shows the reader the raw data underlying the regressions.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Robustness: Investment per Capita under Alternative Specifications"
**Page:** 20
- **Formatting:** The column headers are a bit crowded. 
- **Clarity:** Column 4 has 425,872 observations. This jump from ~6,000 in other columns should be more clearly signaled in the table itself (e.g., a "Level" row: Constituency vs. Commune).
- **Storytelling:** Good grouping of robustness checks.
- **Labeling:** "treated_placebo" is a variable name; it should be relabeled "Placebo Treatment" for a professional look.
- **Recommendation:** **REVISE**
  - Clean up the variable names in the stub (no underscores).
  - Add a row for "Unit of Observation" (Constituency vs. Commune).

---

## Appendix Exhibits

### Table A1: "Cumulard Classification of XIV Legislature Deputies"
**Page:** 28
- **Recommendation:** **KEEP AS-IS** (Simple and effective).

### Figures A1, A2, A3: "Event Studies (Individual)"
**Page:** 29-30
- **Storytelling:** These are somewhat redundant given Figure 2 in the main text.
- **Recommendation:** **KEEP AS-IS** (Standard for appendices).

### Table A2: "Triple-Difference: Rural Interaction (Commune Level)"
**Page:** 31
- **Recommendation:** **PROMOTE TO MAIN TEXT**. The discussion in Section 7.2 (Heterogeneity) is one of the more interesting parts of the paper. This table provides the evidence for the urban/rural split and should be visible without flipping to the appendix.

### Table A3: "HonestDiD Sensitivity Analysis: Investment Per Capita"
**Page:** 31
- **Recommendation:** **KEEP AS-IS** (Required for modern DiD papers).

### Figure A4: "Share of Cumulard Constituencies by Département"
**Page:** 32
- **Clarity:** Very difficult to read. 90+ rows in a bar chart is too much.
- **Storytelling:** It shows geographic variation, but does it matter for the identification? Probably not.
- **Recommendation:** **REVISE or REMOVE**. If kept, consider a heat map of France (Choropleth map) instead of a bar chart. It would be much more intuitive for a reader to see the "rural/urban" or "North/South" distribution visually.

---

## Overall Assessment

- **Exhibit count:** 3 main tables, 3 main figures, 2 appendix tables, 4 appendix figures (one multi-panel).
- **General quality:** High. The exhibits follow the "minimalist" aesthetic preferred by the AER/QJE. The use of per-capita thousands of euros is consistent.
- **Strongest exhibits:** Figure 1 (Event Study) and Table 2 (Main Results).
- **Weakest exhibits:** Figure A4 (unreadable bar chart) and Table 3 (needs cleaner labels).
- **Missing exhibits:** A **Map of France** showing the treatment/control constituencies would be highly beneficial in Section 2 or 3 to demonstrate the "geographically widespread" nature mentioned in the text.

### Top 3 Improvements:
1.  **Add a Treatment Map:** Replace or supplement Figure A4 with a map of France showing cumulard vs. non-cumulard constituencies.
2.  **Promote Heterogeneity:** Move Table A2 (Urban/Rural split) to the main text. It is the only place where a non-null result appears, and it is vital for the "Storytelling" aspect of the paper.
3.  **Clean up Robustness Table:** Relabel "treated_placebo" and add clear "Unit of Observation" indicators to Table 3 to help the reader navigate the change in sample size.