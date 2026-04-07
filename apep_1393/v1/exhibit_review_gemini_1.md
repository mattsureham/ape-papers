# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-04-07T21:49:16.664098
**Route:** Direct Google API + PDF
**Tokens:** 21517 in / 1812 out
**Response SHA256:** e5e1cb53d7170683

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics"
**Page:** 9
- **Formatting:** Clean, standard academic style. However, the alignment of numbers is inconsistent; decimal points should be vertically aligned to allow for quick comparison of magnitudes across rows.
- **Clarity:** Good. It provides a clear overview of the sample. The variable names in the first column are slightly technical (e.g., "AW Denial Gap"); using more descriptive labels (e.g., "Asian-White Denial Gap") would be better.
- **Storytelling:** Essential. It establishes the baseline gaps and the variation in the instrument.
- **Labeling:** Clear. The note explains the sample restrictions and the definition of the merger instrument well.
- **Recommendation:** **REVISE**
  - Align numbers by decimal point.
  - Replace technical variable names (AW, BW) with descriptive English (Asian-White, Black-White).

### Table 2: "First Stage and Reduced Form"
**Page:** 13
- **Formatting:** Use of "bw_denial_gap" in the header is unprofessional; this is a variable name, not a journal-ready title. Columns are well-spaced.
- **Clarity:** The juxtaposition of first-stage and reduced-form results is standard but could be clearer. Column (3) uses scientific notation ($7.5 \times 10^{-5}$), which is hard to parse; consider rescaling the variable (e.g., "per 1,000 applicants") to show standard decimals.
- **Storytelling:** Strong. It shows the link between the instrument and both the endogenous variable and the outcomes.
- **Labeling:** Significance stars are used but should be explicitly defined in the note (* p<0.1, etc.). Standard errors are correctly in parentheses.
- **Recommendation:** **REVISE**
  - Change column headers from variable names to descriptive titles.
  - Rescale Asian-White gap to avoid scientific notation.
  - Define significance stars in the note.

### Table 3: "IV Estimates: Effect of Branch Closures on Racial Mortgage Gaps"
**Page:** 14
- **Formatting:** The table is cut off on the right side in the PDF (Columns 5+ are missing/unreadable).
- **Clarity:** Because the table is cut off, the "Overall" column is unreadable.
- **Storytelling:** This is the "money table" of the paper. It highlights that the effect is specific to the Black-White gap.
- **Labeling:** Clear, though again, it uses code-like variable names in headers.
- **Recommendation:** **REVISE**
  - Fix the layout so the table fits within the page margins.
  - Use Panels (Panel A: Denial Gaps, Panel B: Rate Spreads) to reduce column clutter and improve vertical flow.

### Table 4: "OLS vs. IV Estimates"
**Page:** 15
- **Formatting:** Standard and clean.
- **Clarity:** Excellent. Side-by-side comparison of OLS and IV is the best way to show the direction of selection bias.
- **Storytelling:** Crucial for the identification narrative.
- **Labeling:** Descriptive and helpful.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "IV Estimates with County Fixed Effects"
**Page:** 16
- **Formatting:** Professional.
- **Clarity:** Clear, though the results are null/imprecise (as noted in the text).
- **Storytelling:** This is a robustness check. Given it's a "bounds exercise," it might be better suited for the appendix to keep the main text focused on the primary results.
- **Recommendation:** **MOVE TO APPENDIX**

## Appendix Exhibits

### Figure 1: "Bank Branch Decline in Sample Counties, 2015–2023"
**Page:** 32
- **Formatting:** Modern and clean. The y-axis "Branches (thousands)" is clear.
- **Clarity:** Very high. It shows a clear downward trend immediately.
- **Storytelling:** This is a "motivation" figure. It belongs in the Introduction or Data section of the main text, not buried in the appendix.
- **Recommendation:** **PROMOTE TO MAIN TEXT**

### Figure 2: "First Stage: Merger Exposure Predicts Branch Closures"
**Page:** 33
- **Formatting:** Binscatter looks professional. Gray confidence interval is a bit wide, reflecting the underlying noise.
- **Clarity:** High. Shows the negative correlation required for the IV.
- **Storytelling:** Visualizes Table 2, Col 1.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Event Study: Black-White Denial Gap Around High Merger Exposure Onset"
**Page:** 35
- **Formatting:** Standard event study plot. The vertical line at $t=-1$ is helpful.
- **Clarity:** Clear pre-trend (flat) and post-trend (divergent). 
- **Storytelling:** This is the most important identification figure. It **must** be in the main text to satisfy reviewers regarding parallel trends.
- **Recommendation:** **PROMOTE TO MAIN TEXT**

### Figure 5: "Heterogeneity: Black-White Denial Gap by Merger Exposure and Minority Share"
**Page:** 36
- **Formatting:** This figure is "busy." The four overlapping lines are difficult to distinguish, especially for colorblind readers or in grayscale printing.
- **Clarity:** Poor. The key message (that the gap is widest in high-merger/high-minority counties) is obscured by the cross-hatching of lines.
- **Storytelling:** Important for mechanisms, but poorly executed.
- **Recommendation:** **REVISE**
  - Split into two panels: Panel A (High Minority Counties), Panel B (Low Minority Counties). In each panel, show High vs. Low Merger Exposure.

### Figure 7: "Pre-Period Balance: High vs. Low Merger Exposure Counties"
**Page:** 38
- **Formatting:** Horizontal bar chart is a great way to show balance.
- **Clarity:** Immediate. One can see that only "Black Share" is slightly off-balance.
- **Storytelling:** Essential for the IV validity.
- **Recommendation:** **PROMOTE TO MAIN TEXT**

### Table 6: "Standardized Effect Sizes"
**Page:** 39
- **Formatting:** Too many decimal places (4-5). Journals prefer 2 or 3.
- **Clarity:** The "Classification" column (e.g., "Large posi") is unconventional and adds little value. The table is very wide.
- **Storytelling:** It's a summary of results already presented. 
- **Recommendation:** **REMOVE** (The text in Section 5.5 "Economic Magnitude" already covers this more effectively).

---

## Overall Assessment

- **Exhibit count:** 5 main tables, 0 main figures, 1 appendix tables, 7 appendix figures
- **General quality:** The tables are very standard "Stata-out" style but need more manual polishing for top-tier journals. The figures are high quality but the most important ones (Event Study, Balance) are hidden in the appendix.
- **Strongest exhibits:** Table 4 (OLS vs IV) and Figure 7 (Balance).
- **Weakest exhibits:** Figure 5 (over-cluttered lines) and Table 3 (formatting/cutoff issues).
- **Missing exhibits:** A map showing the "Geographic Incidence of Mergers/Closures" would be highly valued by AER/QJE readers to understand the spatial variation being exploited.

**Top 3 improvements:**
1.  **Rebalance Main/Appendix:** Move Figure 4 (Event Study), Figure 7 (Balance), and Figure 1 (Trend) into the main text. A paper without figures in the main text is harder to read.
2.  **Professionalize Table Headers:** Remove all underscores and code names (bw_denial_gap) from labels. Use "Black-White Denial Gap (pp)".
3.  **Fix Table 3:** Ensure the primary results table is fully visible and use a Panel structure to group the five different outcome variables logically.