# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-04T13:49:26.693088
**Route:** Direct Google API + PDF
**Tokens:** 17357 in / 1702 out
**Response SHA256:** 7bb4176c3f34efbe

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Pre-Treatment Period (2014–2017)"
**Page:** 10
- **Formatting:** Clean and professional. Follows standard "Table 1" balance table conventions. Numbers are generally aligned, though decimal alignment could be tighter for the "Mean Transactions" row.
- **Clarity:** Very high. Clearly shows the level differences (especially in apartment share) that drive the paper's mechanism.
- **Storytelling:** Essential. It justifies the use of commune fixed effects and sets the stage for the "compositional shift" argument.
- **Labeling:** Good. Note clarifies the sample restrictions and the sampling of control cities.
- **Recommendation:** **REVISE**
  - Change "Pct Apartment (%)" to "Apartment Share" (having both Pct and % is redundant).
  - Add a "Difference" column with a t-stat or p-value to formally show the lack of balance in levels, which reinforces the need for the DiD approach.

### Table 2: "Effect of Action Cœur de Ville on Property Markets"
**Page:** 15
- **Formatting:** Excellent. Standard journal layout with clear grouping of Fixed Effects (FE).
- **Clarity:** High. Moving from naïve DiD (1) to the preferred specification (2/3) and then the transaction level (5/6) tells the paper's core story perfectly.
- **Storytelling:** This is the "money table" of the paper. It shows the aggregate effect disappearing once micro-controls are added.
- **Labeling:** Well-labeled. Significance stars and clustering are properly noted.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Event Study: Effect of ACV on Residential Property Prices"
**Page:** 16
- **Formatting:** Modern and clean. The use of a shaded 95% CI is standard. The vertical dashed line for the announcement is helpful.
- **Clarity:** Good. The pre-trend is clearly flat, and the post-treatment emergence is visible.
- **Storytelling:** Crucial for identification. It validates the parallel trends assumption.
- **Labeling:** Clear. 
- **Recommendation:** **REVISE**
  - The y-axis label is a bit cluttered: "DiD Coefficient (log price/m²)". Simply "Log Price per m²" is sufficient as the caption explains it is a DiD coefficient.
  - Increase font size of the "ACV Announcement" text for better readability.

### Figure 2: "Residential Property Prices: ACV vs. Control Cities"
**Page:** 17
- **Formatting:** Professional line plot.
- **Clarity:** Good. Shows raw data trends.
- **Storytelling:** Useful for showing the "zoom town" recovery in 2020. However, it is somewhat redundant with Figure 1.
- **Labeling:** Axis labels and legend are clear.
- **Recommendation:** **MOVE TO APPENDIX**
  - While helpful, the event study (Figure 1) is the primary identification proof. This raw trend plot is better suited for a data appendix to support the Table 1 levels.

### Table 3: "Heterogeneity by Property Type and Size"
**Page:** 18
- **Formatting:** Consistent with Table 2.
- **Clarity:** Good. Logical columns.
- **Storytelling:** Directly supports the "compositional shift" theory by showing that within specific categories (Apartments, Houses), the price effect is null.
- **Labeling:** Clearly defined categories in the header.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Property Transaction Volume: ACV vs. Control Cities"
**Page:** 19
- **Formatting:** Similar style to Figure 2.
- **Clarity:** High.
- **Storytelling:** Important for the argument that the program stimulated market activity/liquidity.
- **Labeling:** Indexed to 2017 = 100 is a smart choice for comparing different sized markets.
- **Recommendation:** **REVISE**
  - Like Figure 2, the raw trends are less rigorous than a coefficient plot. Consider converting this into a volume event study (similar to Figure 1) to show the causal impact on transaction counts more formally.

### Figure 4: "Placebo Tests: Fake Treatment Dates vs. Real"
**Page:** 20
- **Formatting:** Clean dot-and-whisker plot.
- **Clarity:** Very high. The contrast between the red (placebo) and blue (real) is effective.
- **Storytelling:** Strong robustness check.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS** (or consolidate with Table 4).

### Figure 5: "Leave-One-Region-Out Sensitivity"
**Page:** 21
- **Formatting:** Standard sensitivity plot.
- **Clarity:** High. Shows the result is not driven by one outlier region.
- **Storytelling:** Standard for top-tier journals to show results aren't idiosyncratic.
- **Labeling:** Regions are clearly listed.
- **Recommendation:** **MOVE TO APPENDIX**
  - This is a secondary robustness check that doesn't change the narrative. Main text space is better used for mechanisms.

### Table 4: "Robustness: Placebo Tests and Leave-One-Region-Out"
**Page:** 22
- **Formatting:** Good use of panels.
- **Clarity:** High.
- **Storytelling:** Redundant with Figures 4 and 5.
- **Labeling:** Clear.
- **Recommendation:** **REMOVE**
  - You already have Figure 4 (Placebo) and Figure 5 (Leave-one-region-out). In top journals, you usually present the data in *either* a table or a figure, not both. The figures are more visually striking for these specific tests.

---

## Appendix Exhibits

### Table 5: "Variable Definitions"
**Page:** 30
- **Formatting:** Simple and clean.
- **Clarity:** High.
- **Storytelling:** Essential for replicability.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 4 main tables, 5 main figures, 1 appendix table, 0 appendix figures.
- **General quality:** Extremely high. The paper adopts a "Compositional Shift" narrative that is very well supported by the sequence of exhibits (Table 2 -> Table 3).
- **Strongest exhibits:** Table 2 (the core results) and Figure 4 (the placebo visualization).
- **Weakest exhibits:** Figure 2 and Figure 5 (not because they are bad, but because they clutter the main text).
- **Missing exhibits:** 
    - **Map of France:** A map showing the 222 treated cities vs. the control communes would be a standard "Figure 1" in an AER/QJE paper to show geographic coverage.
    - **Property Characteristics Balance:** A more detailed table in the appendix showing balance (or lack thereof) on floor area, room counts, etc., would strengthen the transaction-level analysis.

- **Top 3 improvements:**
  1. **Consolidate Robustness:** Remove Table 4 and move Figure 5 to the Appendix. This streamlines the main text.
  2. **Add a Map:** Create a "Figure 1: Geographic Distribution of ACV Cities" to orient the reader to the French context.
  3. **Formalize Volume Analysis:** Turn Figure 3 into a formal Event Study plot (coefficients on log transaction volume) to match the rigor of Figure 1.