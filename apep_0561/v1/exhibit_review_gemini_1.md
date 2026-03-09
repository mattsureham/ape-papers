# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-09T17:58:59.846309
**Route:** Direct Google API + PDF
**Tokens:** 17877 in / 1847 out
**Response SHA256:** be4e8e7b6113e18c

---

This review evaluates the visual exhibits of the paper "Does State Withdrawal Fuel the Far Right? Evidence from France’s Rural Tax Zones" according to the standards of top-tier economics journals (AER, QJE, etc.).

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Pre-Treatment Characteristics (2012 Presidential Election)"
**Page:** 8
- **Formatting:** Generally professional. Uses standard booktabs-style horizontal lines. Decimal alignment is good.
- **Clarity:** Very clean. Logical grouping of "Losers" vs. "Stayers."
- **Storytelling:** Essential. Establishes the validity of the control group by showing that while differences are statistically significant (due to large N), they are substantively small.
- **Labeling:** Clear. The note explains the groups and the source of p-values.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Effect of Losing ZRR Status on FN/RN Vote Share"
**Page:** 12
- **Formatting:** Professional. Good use of parenthetical standard errors.
- **Clarity:** Logical progression from baseline to weighted and log specifications.
- **Storytelling:** This is the "money table." It clearly shows the counterintuitive negative sign across all specifications.
- **Labeling:** The note is comprehensive. However, Column (2) title "Extended Post" is slightly confusing—the note explains it includes 2019, but 2019 is a European election, not a Presidential one.
- **Recommendation:** **REVISE**
  - Change the header for Column (2) to "Incl. 2019 Euro Election" to be more explicit.
  - Fix the typo in the note: `Post = ⊮[year ≥ 2022]` contains a rendering error (the "is not" symbol instead of an indicator function or "1").

### Figure 1: "Event Study: Effect of Losing ZRR Status on FN/RN Vote Share"
**Page:** 13
- **Formatting:** Clean, but the "ggplot2" default grey background grid is often discouraged in top journals.
- **Clarity:** Excellent. The reference year (2017) is clearly marked. The divergence in 2022 is immediately visible.
- **Storytelling:** Crucial for defending the parallel trends assumption.
- **Labeling:** Y-axis and X-axis are well-labeled.
- **Recommendation:** **REVISE**
  - Remove the grey background grid; use a white background with thin horizontal lines only.
  - Increase the font size of the axis labels for better readability in print.

### Figure 2: "Mean FN/RN Vote Share: Losers vs. Stayers"
**Page:** 14
- **Formatting:** Good use of colors and line markers.
- **Clarity:** Very high. 10-second parse: "The groups moved together until 2017, then diverged slightly."
- **Storytelling:** Important "raw data" companion to Figure 1.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS** (or move to Appendix if space is tight, as Figure 1 is the causal evidence).

### Figure 3: "FN/RN Vote Share by ZRR Treatment Group"
**Page:** 15
- **Formatting:** High quality. Four distinct colors are distinguishable.
- **Clarity:** A bit busier than Figure 2, but necessary to show the "Gainers" and "Never" groups.
- **Storytelling:** Shows the "level" differences that justify the symmetric test discussion.
- **Labeling:** Legend is clear.
- **Recommendation:** **REVISE**
  - Change "Never ZRI" in the legend to "Never ZRR" to match the text (typo on page 15).

### Table 3: "Symmetric Test: Losing vs. Gaining ZRR Status"
**Page:** 16
- **Formatting:** Consistent with Table 2.
- **Clarity:** Clear contrast between the two coefficients.
- **Storytelling:** Vital for the paper’s argument that the "loser" result is the one to trust due to the failure of parallel trends in the "gainer" sample.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Symmetric Event Study: Effect of Gaining ZRR Status on FN/RN Vote Share"
**Page:** 16
- **Formatting:** Same grid issue as Figure 1.
- **Clarity:** The huge pre-trend is obvious.
- **Storytelling:** Supports the "warning" in Table 3.
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - Switch to a white background.
  - Ensure the Y-axis scale is comparable to Figure 1 if possible, or highlight that the scale here is much larger (up to 4.0 vs 0.75).

### Table 4: "Effect of Losing ZRR Status on Alternative Electoral Outcomes"
**Page:** 17
- **Formatting:** Professional.
- **Clarity:** High.
- **Storytelling:** The result in Column (3) is the most interesting part of the mechanism section.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Event Study: Effect of Losing ZRR Status on Voter Turnout"
**Page:** 18
- **Formatting:** Grid issue again.
- **Clarity:** Shows a clear null.
- **Storytelling:** Supports the "no mobilization" claim.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**
  - The main text is getting "Figure heavy." Since this is a null result on a secondary outcome (turnout), it belongs in the robustness/appendix section to keep the reader focused on the vote share result.

---

## Appendix Exhibits

### Table 5: "Standardized Effect Sizes for Main Outcomes"
**Page:** 32
- **Formatting:** Very different from the main tables. It looks more like a summary spreadsheet than a journal table.
- **Clarity:** A bit cluttered with the "Research Question" and "Method" text inside the table area.
- **Storytelling:** Helpful for meta-analysis but less important for the causal narrative.
- **Labeling:** The note is very long.
- **Recommendation:** **REVISE**
  - Move the "Research Question," "Treatment," "Data," etc., text into the Table Note, not the table body.
  - Simplify the columns; "SD(X)" is empty for all rows—remove it.

---

## Overall Assessment

- **Exhibit count:** 4 main tables, 5 main figures, 1 appendix table, 0 appendix figures.
- **General quality:** The exhibits are of high academic quality. The tables are formatted correctly for top journals. The figures are informative but suffer from "default" software styling (grey grids) that looks slightly less professional than custom Stata/R themes used in the AER.
- **Strongest exhibits:** Table 2 (Main results), Figure 1 (Event study).
- **Weakest exhibits:** Figure 5 (Secondary null result taking up main text space), Table 5 (Formatting).
- **Missing exhibits:** 
    1. **A Map:** For a paper about "Rural Tax Zones" in France, a map showing the "Loser" communes vs. "Stayer" communes is **glaringly missing**. This is standard for any place-based policy paper in the QJE or AER.
    2. **Heterogeneity Table:** The text describes heterogeneity by commune size and prior FN support (Sections 6.2 and 6.3) but does not provide a table for them. These should be in a Table (likely Table 5) rather than just described in the text.

- **Top 3 improvements:**
  1. **Add a Map:** Visualize the geographic distribution of the 2015 reclassification.
  2. **Professionalize Figure Aesthetics:** Move to white backgrounds, remove outer boxes, and increase font sizes.
  3. **Consolidate Heterogeneity:** Create a table for the commune-size and prior-vote-share heterogeneity results mentioned in the text. These are more important than the "Standardized Effect Sizes" currently in the appendix.