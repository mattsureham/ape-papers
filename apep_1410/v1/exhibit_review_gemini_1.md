# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-04-08T10:30:33.512754
**Route:** Direct Google API + PDF
**Tokens:** 14237 in / 1990 out
**Response SHA256:** 2bf15169ee18b765

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Swiss Occupational Pension System, 2004–2024"
**Page:** 7
- **Formatting:** Clean and professional. Follows the standard "three-line" rule (top, bottom, and header separator). Numbers are generally well-aligned.
- **Clarity:** Excellent. It provides a clear overview of the variation in the treatment variable (rate cut) and the scale of the system (millions of insured).
- **Storytelling:** Essential. It establishes the "stock" vs "flow" distinction mentioned in the text (though the table title doesn't explicitly label the share as stock-based, the notes do).
- **Labeling:** Good. "pp" and "%" are clearly noted.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Capital Withdrawal Share Among Pension Beneficiaries, 2004–2024"
**Page:** 9
- **Formatting:** Modern and clean. The use of dashed vertical lines to mark reform steps is excellent for identifying the "shocks."
- **Clarity:** High. The reader can immediately see the non-monotonic relationship between the reform steps and the outcome.
- **Storytelling:** This is the "hook" of the paper. It visualizes the raw paradox: the rate is falling, but the capital share isn't rising as fast as expected.
- **Labeling:** Clear. The legend inside the plot area for the dashed lines is helpful.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Effect of BVG Conversion Rate Cut on Capital Withdrawal"
**Page:** 10
- **Formatting:** This is a "horizontal" regression table (results in rows). While efficient for space, top journals (AER/QJE) almost exclusively use "vertical" tables (specifications in columns).
- **Clarity:** Low. It is difficult to compare coefficients across models when they are stacked vertically. The "Intensive margin" row (Row 5) has a coefficient in the hundreds of thousands, which makes the scale of the other rows look tiny and hard to read.
- **Storytelling:** This table tries to do too much: baseline, gender heterogeneity, intensive margin, and placebo.
- **Labeling:** Standard errors are in parentheses, which is good. Units for Row 5 (CHF) should be more prominent.
- **Recommendation:** **REVISE**
  - **Change:** Convert to a standard vertical regression table. Columns 1–2 should be the main aggregate results (with and without trend). 
  - **Split:** Move the "Intensive margin" (Column 5) and "Placebo" (Column 6) to a separate table or the appendix. Mixing different outcome units in one table is distracting.

### Figure 2: "Capital Share by Reform Step"
**Page:** 11
- **Formatting:** Standard coefficient plot. The zero-line is present.
- **Clarity:** Good, but the x-axis labels are a bit crowded.
- **Storytelling:** Effectively shows that Step 1 had a massive negative effect, which is the core of the "squeeze" argument.
- **Labeling:** Explicitly mentions "Relative to pre-reform period," which is necessary for interpretation.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Capital Share by Pension Fund Autonomy Type"
**Page:** 12
- **Formatting:** Good use of colors and shapes to distinguish categories.
- **Clarity:** A bit cluttered. The "Semi-autonomous" line is highly volatile and oscillates, which might be due to small sample noise or reporting, making the chart "spiky."
- **Storytelling:** This is the most important figure for the mechanism. It clearly shows the divergence between Autonomous (upward) and Collective (downward) funds.
- **Labeling:** The subtitle "Collective funds are most exposed..." is a "declarative title" style often favored by AEJ/AER.
- **Recommendation:** **REVISE**
  - **Change:** Consider using a "Small Multiples" approach (three separate panels side-by-side) rather than one overlaid chart. The overlapping lines make it hard to see the individual trends, especially for the Semi-autonomous group.

### Table 3: "Heterogeneity by Pension Fund Autonomy Type"
**Page:** 12
- **Formatting:** Same issue as Table 2—it is a horizontal table.
- **Clarity:** Reasonable because units are consistent here.
- **Storytelling:** Redundant with Figure 3 but provides the statistical significance ($p$-values) mentioned in the text.
- **Labeling:** $N=21$ for Collective but $N=42$ for others—the notes should explain this (likely due to the gender split mentioned in Section 4.2).
- **Recommendation:** **REVISE**
  - **Change:** Convert to vertical format. Group the three fund types as columns.

### Figure 4: "Lump-Sum Capital Withdrawals at Retirement by Gender"
**Page:** 14
- **Formatting:** Clean.
- **Clarity:** Good. The y-axis is in "thousands," which is clearly labeled.
- **Storytelling:** This shows the "raw" counts. It confirms that men dominate the aggregate volume.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX** (The gender share is more relevant for the "annuity puzzle" than the raw count of beneficiaries).

### Figure 5: "Capital Share: Retirement vs. Disability Pensions (Placebo)"
**Page:** 15
- **Formatting:** Professional.
- **Clarity:** The contrast between the treatment (top line) and placebo (bottom line) is stark and effective.
- **Storytelling:** Strong evidence against a general "shift to capital" confounder.
- **Labeling:** Explicitly notes the change in BFS methodology in the notes—essential for transparency.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Capital Withdrawal Share vs. Cumulative Conversion Rate Cut"
**Page:** 16
- **Formatting:** Standard binscatter/scatter with fit line.
- **Clarity:** The "stacking" of points at 0.4 on the x-axis is a bit confusing until you realize it represents multiple post-2014 years.
- **Storytelling:** This illustrates the "raw" correlation before controlling for the trend.
- **Recommendation:** **REMOVE** (Figure 1 and Table 2 already tell this story more effectively. A scatter plot of a time series against a step function is often less intuitive than a standard time-series plot).

### Figure 7: "Average Capital Withdrawal per Beneficiary at Retirement"
**Page:** 17
- **Formatting:** Consistent with Figure 4.
- **Clarity:** High.
- **Storytelling:** This is the "Intensive Margin" result. It is a critical piece of the "Compositional Effects" argument in Section 6.
- **Labeling:** Y-axis in CHF thousands is clear.
- **Recommendation:** **REVISE**
  - **Change:** This should be a Main Text figure, but it needs a more descriptive title like "Intensive Margin: Average Withdrawal Amount by Gender."

## Appendix Exhibits

### Table (Unnumbered): "Conversion Rate Schedule"
**Page:** 23
- **Formatting:** Basic. 
- **Recommendation:** **KEEP AS-IS** (Functions well as a reference table).

---

## Overall Assessment

- **Exhibit count:** 4 main tables, 7 main figures, 1 appendix table, 0 appendix figures.
- **General quality:** High. The figures are modern (likely ggplot2/python based) and the tables are clean. The paper is "over-figured"—it uses figures for things that are already well-covered in tables.
- **Strongest exhibits:** Figure 1 (The Hook), Figure 5 (The Placebo), Figure 3 (The Mechanism).
- **Weakest exhibits:** Table 2 (Horizontal format), Figure 6 (Redundant).
- **Missing exhibits:** A table showing the **Flow-based** vs **Stock-based** results side-by-side in a regression would be very helpful, as the text discusses their differences extensively.

### Top 3 Improvements:
1.  **Pivot Tables to Vertical:** Convert Tables 2 and 3 from the "horizontal" row-based format to the standard "vertical" column-based regression format used in Top-5 journals.
2.  **Consolidate Figures:** The paper has 7 figures in the main text. Move Figure 4 (Raw counts) and Figure 6 (Scatter) to the appendix to keep the main text focused on the causal "puzzle."
3.  **Refine the Intensive Margin Story:** Table 2 (Row 5) and Figure 7 both show the intensive margin. Create one dedicated "Intensive Margin" table that shows the regression results for different subgroups (Men/Women/Fund Types) to support the compositional shift theory.