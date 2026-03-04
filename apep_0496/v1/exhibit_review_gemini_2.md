# Exhibit Review — Gemini 3 Flash (Round 2)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-04T10:31:38.060992
**Route:** Direct Google API + PDF
**Tokens:** 19437 in / 1827 out
**Response SHA256:** e8c22e0ee0a97940

---

This review evaluates the visual exhibits of "The Stigma of Priority" based on the standards of top-tier economics journals (AER, QJE, etc.).

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Property Transactions Near REP/Non-REP Boundaries"
**Page:** 12
- **Formatting:** Clean and professional. Proper use of horizontal rules (booktabs style). Number alignment is good.
- **Clarity:** High. Clearly compares the two groups across price and property characteristics.
- **Storytelling:** Essential. It establishes the "raw" 21% price gap that the RDD and parametric models later debunk. 
- **Labeling:** Good. Notes explain the sample restrictions and N.
- **Recommendation:** **REVISE**
  - Add a "Difference" column with t-stats or p-values for the comparison between Non-REP and REP sides. This is standard to show covariate (im)balance early on.
  - The units for "Mean Surface" are in the text (m²) but should be in the header.

### Figure 1: "Property Prices at Education Priority Zone Boundaries"
**Page:** 15
- **Formatting:** Good use of loess fits and confidence intervals. Dots are appropriately sized.
- **Clarity:** The core message is clear (positive jump at $X=0$). However, the y-axis (Log Price) is difficult for a casual reader to translate to Euros.
- **Storytelling:** This is the "money" shot of the paper. It successfully shows the counter-intuitive jump.
- **Labeling:** Axis labels are clear. Legend for "Non-REP" vs "REP" side is helpful.
- **Recommendation:** **REVISE**
  - Change the y-axis to show "Log Price per m²" but include a secondary axis or label indicating the approximate Euro value to make the 5.3% gap more "real" to the reader.
  - Remove the gray background grid for a cleaner "QJE-style" look.

### Table 2: "Main Results: Parametric Boundary Estimates"
**Page:** 17
- **Formatting:** Professional. Standard errors in parentheses, significance stars defined.
- **Clarity:** Logical progression from raw correlation to fully controlled model.
- **Storytelling:** Vital. It tells the story of how the "stigma" (negative coefficient) is actually a geographic sorting artifact (positive/null coefficient).
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Annual Boundary Gaps: REP/Non-REP Price Discontinuity by Year"
**Page:** 18
- **Formatting:** Standard coefficient plot. The shaded 95% CI is clean.
- **Clarity:** Very high. The downward trend is immediately obvious.
- **Storytelling:** Supports the "Time Dynamics" section. It suggests the policy is either succeeding or the stigma is fading.
- **Labeling:** Excellent. Title is descriptive.
- **Recommendation:** **KEEP AS-IS** (Consider merging with a table if space is tight, but as a figure, it’s strong).

### Figure 3: "Transaction Density at REP/Non-REP Boundaries"
**Page:** 19
- **Formatting:** Clean histogram. Red dashed line at zero is helpful.
- **Clarity:** Shows the "McCrary" violation clearly.
- **Storytelling:** Important for transparency. It admits the sorting issue honestly.
- **Labeling:** Axis and notes are complete.
- **Recommendation:** **MOVE TO APPENDIX**
  - While important for the ID strategy, it’s a diagnostic. Most top journals prefer the main text to focus on results, moving density tests to the appendix unless the paper is specifically about RDD methodology.

### Table 3: "Covariate Balance at REP/Non-REP Boundaries"
**Page:** 20
- **Formatting:** Standard.
- **Clarity:** High.
- **Storytelling:** Necessary check.
- **Labeling:** Good.
- **Recommendation:** **MOVE TO APPENDIX**
  - Combine this with Figure 4. Like the density test, balance tables are usually relegated to the appendix in modern AER/QJE papers to save space for mechanism analysis.

### Figure 4: "Covariate Smoothness at REP/Non-REP Boundaries"
**Page:** 20
- **Formatting:** Multi-panel.
- **Clarity:** Shows the discontinuities in surface area and apartment share.
- **Storytelling:** Proves the sorting story.
- **Labeling:** Labels are a bit small compared to Figure 1.
- **Recommendation:** **MOVE TO APPENDIX**

### Figure 5: "Bandwidth Sensitivity of Boundary Estimates"
**Page:** 21
- **Formatting:** Clean.
- **Clarity:** Shows stability.
- **Storytelling:** Robustness check.
- **Recommendation:** **MOVE TO APPENDIX**

### Table 4: "Robustness: Bandwidth Sensitivity and Donut Specifications"
**Page:** 22
- **Formatting:** Two panels (A and B). Very professional.
- **Clarity:** High.
- **Storytelling:** Crucial robustness. The donut result (Panel B) is actually quite important because it shows the effect is hyper-local.
- **Recommendation:** **REVISE**
  - Move Panel A (Bandwidth) to Appendix.
  - Keep Panel B (Donut) in the main text, perhaps as a small table or integrated into Table 2, as it addresses a major identification threat.

### Figure 6: "REP Boundary Gap by Private School Availability"
**Page:** 24
- **Formatting:** Excellent use of color to distinguish the two regimes.
- **Clarity:** Striking. The reversal of the slope is clear.
- **Storytelling:** This is the "Mechanism" result. It’s the strongest part of the paper's argument for *why* we see the results we do.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Table 5: "Placebo Tests at Shifted Boundary Locations"
**Page:** 34
- **Formatting:** Consistent with main text.
- **Recommendation:** **KEEP AS-IS** (Good supporting evidence).

### Table 6: "Year-by-Year RDD Estimates at REP/Non-REP Boundaries"
**Page:** 35
- **Formatting:** Clean.
- **Storytelling:** Redundant with Figure 2.
- **Recommendation:** **KEEP AS-IS** (Standard practice to provide the table version of a figure in the appendix).

---

## Overall Assessment

- **Exhibit count:** 2 main tables, 3 main figures (after recommended moves), 3 appendix tables, 4 appendix figures.
- **General quality:** Extremely high. The exhibits use modern R/Stata aesthetics (clean, no-nonsense) that match the "look and feel" of the AEA journals.
- **Strongest exhibits:** Figure 1 (Visual RDD) and Figure 6 (Private School Mechanism).
- **Weakest exhibits:** Figure 3 and Figure 5 (simply because they are standard diagnostics that clutter the main narrative).

- **Missing exhibits:**
  1. **Map of REP Zones:** A spatial paper needs a map. A figure showing the distribution of REP schools and a "zoom-in" on a specific boundary would help readers visualize the treatment.
  2. **Heterogeneity by Region Table:** While the text discusses Île-de-France vs. the rest of France, a table showing these coefficients side-by-side would be very powerful.

- **Top 3 improvements:**
  1. **Strategic Relocation:** Move Figures 3, 4, 5 and Table 3 to the Appendix. This streamlines the main text to focus on the "Counter-intuitive result" $\rightarrow$ "Sorting explanation" $\rightarrow$ "Private school mechanism."
  2. **Add a Map:** Create a "Figure 0" showing the geography of the REP policy in France.
  3. **Y-Axis Interpretation:** In Figures 1 and 6, provide a clearer sense of the Euro magnitude, perhaps by adding a note like "A 0.05 log point increase corresponds to ~€11,000 for the median property."