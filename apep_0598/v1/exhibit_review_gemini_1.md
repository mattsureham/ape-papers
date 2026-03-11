# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-11T14:43:10.891174
**Route:** Direct Google API + PDF
**Tokens:** 21517 in / 1986 out
**Response SHA256:** 64f58fef754972ba

---

This review evaluates the visual exhibits of the paper "Forced Into the Light: Capital Controls and the Accidental Formalization of Greece’s Shadow Economy" against the standards of top-tier economics journals (AER, QJE, etc.).

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Monthly Retail Trade Turnover (2015 = 100)"
**Page:** 11
- **Formatting:** Generally clean. However, "Panel A" implies a "Panel B" which is missing. The vertical alignment of country names is good.
- **Clarity:** Clear, though providing 14 donor countries in a main-text summary table is borderline excessive. 
- **Storytelling:** It establishes the data range. It would be more impactful if it included a "Donor Mean" row to contrast with Greece directly.
- **Labeling:** Clear. Source note is present.
- **Recommendation:** **REVISE**
  - Remove "Panel A" label if no Panel B exists.
  - Add a "Donor Average" row at the bottom of the list to allow for a quick 10-second comparison with Greece.

### Table 2: "Greece Retail Sectors by Cash Intensity"
**Page:** 12
- **Formatting:** Professional. Good use of horizontal rules.
- **Clarity:** Excellent. This is the "motivating fact" table. The "Jul 2015 Drop (%)" column perfectly illustrates the paper's core mechanism.
- **Storytelling:** Strong. It directly supports Prediction 1.
- **Labeling:** Source and calculation details are clear in the notes.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Pre-Treatment Covariate Balance: Greece vs. Donor Pool (2010–2014 Averages)"
**Page:** 12
- **Formatting:** Clean. 
- **Clarity:** Numbers are easy to read.
- **Storytelling:** Essential for SCM validity. It shows where Greece is a good match (GDP) and where it is not (Unemployment), which justifies the SCM approach.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Cross-Sector Difference-in-Differences: Cash Intensity and Retail Turnover"
**Page:** 16
- **Formatting:** Professional. Standard errors in parentheses.
- **Clarity:** Shows both continuous and binary treatments.
- **Storytelling:** This is the primary result table. The inclusion of t-values and p-values is standard, though top journals often prefer just stars and standard errors to save space.
- **Labeling:** Note is very thorough, particularly regarding the wild cluster bootstrap.
- **Recommendation:** **REVISE**
  - Add significance stars (*, **, ***) to the estimates to match journal conventions.
  - Decimal-align the "Estimate" and "SE" columns.

### Figure 1: "Synthetic Control: Greece vs. Synthetic Greece, Monthly Retail Turnover (2015 = 100)"
**Page:** 18
- **Formatting:** Clean "ggplot2" style.
- **Clarity:** The divergence after the vertical dashed line is unmistakable. 
- **Storytelling:** High impact. It shows the aggregate cost of the shock.
- **Labeling:** Legend is clear. Y-axis label is descriptive. 
- **Recommendation:** **REVISE**
  - Increase the font size of the axis tick labels and legend. Top journals often print figures at 1-column width; these labels would be too small.

### Table 5: "Synthetic Control Estimates: Gap Between Greece and Synthetic Greece"
**Page:** 19
- **Formatting:** Standard.
- **Clarity:** Very high. Breaks down the effect by time horizons.
- **Storytelling:** Crucial for the "Hysteresis" argument (showing the gap grows over time).
- **Labeling:** Notes clearly explain the calculation.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Synthetic Control Weights"
**Page:** 19
- **Formatting:** Slightly sparse. 
- **Clarity:** It's just one country (Portugal). 
- **Storytelling:** While important, this is a "validity check" exhibit.
- **Recommendation:** **MOVE TO APPENDIX** (specifically to Section B.2) to make room for more results in the main text.

### Figure 2: "Treatment Effect Gap: Greece Minus Synthetic Greece"
**Page:** 20
- **Formatting:** Good.
- **Clarity:** Shows the raw gap. 
- **Storytelling:** Redundant with Figure 1. Figure 1 shows the levels (which readers find more intuitive); this just subtracts them. 
- **Recommendation:** **REMOVE** (or move to Appendix). Figure 1 is sufficient for the main text.

### Figure 3: "Retail Turnover by Sector and Cash Intensity, Greece"
**Page:** 21
- **Formatting:** Distinct colors used for the three sectors.
- **Clarity:** Very high. This is the "money shot" figure of the paper.
- **Storytelling:** Perfectly visualizes the monotonic ordering.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS** (Consider making it Figure 1 to motivate the paper earlier).

### Figure 4: "VAT Revenue Index: Greece vs. Donor Countries (2014 = 100)"
**Page:** 22
- **Formatting:** Consistent with other figures.
- **Clarity:** Good contrast between Greece and Donor average.
- **Storytelling:** Vital for the "formalization" mechanism.
- **Labeling:** Descriptive title and notes.
- **Recommendation:** **KEEP AS-IS**

### Table 7: "VAT Revenue: Greece vs. Donor Countries" & Table 8: "VAT-to-GDP Ratio: Greece vs. Donor Countries"
**Page:** 22 & 23
- **Formatting:** Identical styles.
- **Storytelling:** Table 7 shows total revenue fell (contraction); Table 8 shows the *ratio* rose (formalization). 
- **Recommendation:** **REVISE (CONSOLIDATE)**. Combine these into a single table with two columns (Outcome 1: VAT Index, Outcome 2: VAT/GDP Ratio). This allows the reader to see the contrast in one glance.

---

## Appendix Exhibits

### Figure 5: "Placebo-in-Space: RMSPE Gaps for All Countries"
**Page:** 24
- **Formatting:** Standard SCM hair plot.
- **Clarity:** Greece (black) is distinguishable.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Distribution of Post/Pre RMSPE Ratios"
**Page:** 25
- **Formatting:** Bar chart is clean.
- **Clarity:** Very clear.
- **Recommendation:** **KEEP AS-IS**

### Table 9: "Leave-One-Out SCM: Post-Treatment Average Gap"
**Page:** 37
- **Formatting:** Clean.
- **Storytelling:** Important given that Portugal has 100% weight.
- **Recommendation:** **KEEP AS-IS**

### Table 10: "Standardized Effect Sizes"
**Page:** 39
- **Formatting:** Very data-heavy.
- **Clarity:** Harder to parse than others.
- **Storytelling:** Good for cross-study comparison, but less central to the narrative.
- **Recommendation:** **KEEP AS-IS** (Appropriately placed at the end of Appendix).

---

## Overall Assessment

- **Exhibit count:** 8 main tables, 4 main figures, 2 appendix tables, 2 appendix figures.
- **General quality:** Extremely high. The exhibits are clean, follow a consistent aesthetic, and are used to "triangulate" the evidence as promised in the intro.
- **Strongest exhibits:** Figure 3 (Sectoral Monotonicity) and Table 2 (Raw data motivating the DiD).
- **Weakest exhibits:** Figure 2 (Redundant) and Table 6 (Too sparse for main text).
- **Missing exhibits:** 
    1. **An Event Study Figure for the Cross-Sector DiD:** While Table 4 gives the coefficient, an event study plot (coefficients by month) is the "gold standard" for DiD papers in top journals to prove parallel trends visually.
- **Top 3 improvements:**
  1. **Consolidate VAT Tables:** Merge Tables 7 and 8 into a single table to highlight the formalization mechanism.
  2. **Add a DiD Event Study Figure:** Create a figure showing the $\beta$ coefficients from Equation 7 (Page 35) to provide a visual test for parallel trends.
  3. **Streamline SCM reporting:** Move Table 6 to the appendix and remove Figure 2 to reduce clutter and focus on the most striking visual evidence (Figures 1 and 3).