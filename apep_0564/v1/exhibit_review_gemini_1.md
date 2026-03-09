# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-09T19:54:03.074502
**Route:** Direct Google API + PDF
**Tokens:** 21517 in / 1797 out
**Response SHA256:** 5aef2619f166295c

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics"
**Page:** 12
- **Formatting:** Generally professional. Use of panels (A, B, C) is excellent for organizing diverse data sources. Horizontal rules are clean.
- **Clarity:** High. Grouping by instrument, labor outcomes, and demographics is logical.
- **Storytelling:** Essential. It establishes the scale of the labor markets being studied and the limited mean of the grant rate (5.7%).
- **Labeling:** Clear. Units (USD) and sample sizes (N) are well-indicated.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "First Stage: Judge Leniency Predicts Asylum Grant Rates"
**Page:** 17
- **Formatting:** Standard journal format. Standard errors are correctly in parentheses.
- **Clarity:** Panel B is slightly cramped. The transition between the panel specification (Panel A) and the cross-sectional balance tests (Panel B) is a bit jarring since the "N" changes significantly (720 to 44).
- **Storytelling:** This is a "diagnostic" table. It successfully shows the strong first stage but immediately flags the failure of the exclusion restriction through Panel B.
- **Labeling:** "Total Population (millions)" is a good specific label.
- **Recommendation:** **REVISE**
  - Increase whitespace between Panel A and Panel B.
  - Explicitly add a row for "Unit of Observation" (Court-Year vs. Court) to help the reader track why N changes.

### Table 3: "Correlations Between Asylum Grant Rates and Local Labor Markets (Diagnostic Exercise)"
**Page:** 19
- **Formatting:** Numbers are mostly decimal-aligned, though the significance stars cause some slight shifts. 
- **Clarity:** The table is very dense. Showing OLS, IV, and IV+Controls in one row is standard, but the varying N across columns (720 vs 500) needs to be very prominent.
- **Storytelling:** This is the "heart" of the negative result. It shows that even with controls, the magnitudes remain suspicious. 
- **Labeling:** Good use of "Placebo" in the row labels to guide the reader's eye.
- **Recommendation:** **KEEP AS-IS** (The density is necessary to show the across-specification stability of the "failed" result).

### Table 4: "Sector Heterogeneity: Treatment vs. Placebo Sectors"
**Page:** 20
- **Formatting:** Clean and professional.
- **Clarity:** Excellent. This is the clearest "10-second" exhibit in the paper. The comparison between Panel A and Panel B makes the identification failure undeniable.
- **Storytelling:** This table is the "smoking gun." It justifies the paper's methodological contribution by showing the placebo sectors respond just as strongly as treatment sectors.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Robustness Checks"
**Page:** 21
- **Formatting:** Minimalist and professional.
- **Clarity:** High. 
- **Storytelling:** Demonstrates that the result isn't a fluke of clustering or specific FE choices.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX** (The paper already establishes the failure of the design; five main-text tables for a "negative" result paper is heavy. This supports the main text but isn't a primary pillar).

### Figure 1: "Leave-one-court-out stability"
**Page:** 22
- **Formatting:** Clean ggplot2 style. The blue horizontal line provides a helpful reference.
- **Clarity:** Labels on the x-axis (court names) are rotated 90 degrees, making them difficult to read without turning the page.
- **Storytelling:** Effective at showing no single outlier (like NYC or SF) drives the correlation.
- **Labeling:** Y-axis is clearly labeled.
- **Recommendation:** **REVISE**
  - If possible, flip the coordinates (horizontal bar chart) so court names are readable on the y-axis.
  - Move to Appendix to streamline the main text flow.

---

## Appendix Exhibits

### Figure 2: "Within-court immigration judge leniency variation"
**Page:** 33
- **Formatting:** Strong professional box-plot visualization.
- **Clarity:** High. Shows the "lottery" aspect vividly.
- **Storytelling:** This is actually a very strong figure for the paper's motivation. It "sells" the potential of the instrument.
- **Labeling:** Axis labels are clear.
- **Recommendation:** **PROMOTE TO MAIN TEXT** (This should be in the Institutional Background or Data section to motivate why judge leniency is such a powerful potential IV).

### Figure 3: "First stage: average judge leniency vs. court-level asylum grant rate"
**Page:** 34
- **Formatting:** Good use of point sizing for weights.
- **Clarity:** Very high.
- **Storytelling:** Visualizes the near-mechanical first stage. 
- **Recommendation:** **KEEP AS-IS** (Good for appendix).

### Figure 4: "IV estimates across outcomes" / Figure 5: "Placebo Comparison"
**Page:** 35-36
- **Formatting:** Clean coefficient plots.
- **Clarity:** Figure 4 and 5 are highly redundant. 
- **Storytelling:** They tell the same story as Table 4. 
- **Recommendation:** **REMOVE FIGURE 4; KEEP FIGURE 5.** Figure 5 is the more effective "storytelling" version because it explicitly contrasts treatment vs. placebo sectors in the legend.

### Figure 6: "Robustness across fixed effects specifications"
**Page:** 37
- **Formatting:** Consistent with other coefficient plots.
- **Clarity:** High.
- **Storytelling:** Visualizes Table 5.
- **Recommendation:** **KEEP AS-IS** (Standard for appendix).

### Figure 7: "Distribution of court-level judge leniency"
**Page:** 38
- **Formatting:** Standard histogram.
- **Clarity:** High.
- **Storytelling:** Shows the variation available at the court level.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Standardized Effect Sizes for Main Outcomes"
**Page:** 39
- **Formatting:** Professional.
- **Clarity:** The "Classification" column is helpful for non-experts.
- **Storytelling:** Quantifies exactly how "implausibly large" the results are.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 5 main tables, 1 main figure, 1 appendix table, 6 appendix figures.
- **General quality:** High. The tables follow standard "top-journal" formatting (no vertical lines, panel structures, clear notes). The figures are clean but suffer from some redundancy.
- **Strongest exhibits:** Table 4 (The Placebo Failure) and Figure 2 (Within-court variation).
- **Weakest exhibits:** Figure 1 (unreadable x-axis labels) and Figure 4 (redundant with Figure 5).
- **Missing exhibits:** A **Map** showing the 44 immigration courts would be a standard and highly effective addition for a paper relying on geographic variation.

**Top 3 Improvements:**
1.  **Promote Figure 2 to the Main Text:** The "50 percentage point gap" is a key hook of the paper. Visualizing it early (Page 5 or 6) makes the motivation much more compelling.
2.  **Add a Geographic Map:** AER/QJE readers expect to see the "spatial footprint" of the data. A map with bubbles for court size/leniency would clarify the "sorting" story (e.g., leniency clustered in coastal cities).
3.  **Consolidate and Flip Figures:** Move Figure 1 to the appendix and flip its axes for readability. Delete Figure 4 to reduce redundancy with Figure 5.