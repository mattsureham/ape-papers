# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-04-07T22:30:37.497589
**Route:** Direct Google API + PDF
**Tokens:** 14237 in / 1944 out
**Response SHA256:** aef817c80f3c1e6d

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: PNIS vs. Non-PNIS Municipalities"
**Page:** 8
- **Formatting:** Clean, but needs refinement. Columns are not decimal-aligned (e.g., SD Coca vs Median). The use of horizontal rules is appropriate (Booktabs style).
- **Clarity:** Good. It clearly shows the selection issue: PNIS municipalities have vastly more coca at baseline.
- **Storytelling:** Essential. It justifies why a simple comparison of means would be biased and motivates the DiD approach.
- **Labeling:** "Munis" should be "Municipalities". "Erad./yr" is jargon; use "Annual Eradication Events".
- **Recommendation:** **REVISE**
  - Decimal-align all numeric columns.
  - Spell out "Municipalities" and "Standard Deviation".
  - Add a column for the difference in means and a p-value for the t-test of equality to formally show the targeting bias.

### Figure 1: "Event Study: Coca Cultivation in PNIS Municipalities"
**Page:** 10
- **Formatting:** Modern look, but the y-axis label is crowded. The shaded confidence interval is professional.
- **Clarity:** High. The "Year +2 spike" annotation is excellent for the "10-second parse."
- **Storytelling:** This is the "money plot" of the paper. It shows the substitution mirage perfectly.
- **Labeling:** The y-axis "ATT (IHS Coca Hectares)" is technically correct but difficult for a general reader. 
- **Recommendation:** **REVISE**
  - Add a secondary y-axis or a note translating the IHS coefficients into percentage changes (approx $100 \times (\exp(\beta)-1)$) for easier interpretation.
  - Remove the internal subtitle "Sun-Abraham estimator..." and move that technical detail entirely to the note.

### Figure 2: "Average Coca Cultivation: PNIS vs. Non-PNIS Municipalities"
**Page:** 11
- **Formatting:** Legend at the bottom is good. Gridlines are a bit heavy.
- **Clarity:** The 2020 spike in the control group (or lack thereof) is hard to distinguish because the PNIS line is so volatile.
- **Storytelling:** Useful for showing raw data trends, but the massive scale difference makes the non-PNIS line look flat.
- **Labeling:** Good.
- **Recommendation:** **REVISE**
  - Use a log scale for the y-axis or create a dual-axis plot so the trends in the non-PNIS (lower volume) municipalities are visible. This helps visually verify parallel trends in the pre-period.

### Table 2: "Effect of PNIS Enrollment on Coca Cultivation"
**Page:** 12
- **Formatting:** Professional. Column headers are clear.
- **Clarity:** Good use of different specifications to show robustness.
- **Storytelling:** Central table. Combining IHS and Levels (Col 4) is smart as it shows the intensive vs. extensive margin conflict.
- **Labeling:** Significance stars are defined correctly. 
- **Recommendation:** **KEEP AS-IS** (Though ensure decimal alignment in a final typeset version).

### Figure 3: "Coca Cultivation Trajectories by PNIS Enrollment Wave"
**Page:** 13
- **Formatting:** Consistent with Figure 2.
- **Clarity:** Very clear. The colors are distinguishable.
- **Storytelling:** Supports the heterogeneity argument. 
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Heterogeneity by PNIS Enrollment Wave"
**Page:** 14
- **Formatting:** Consistent with Table 2.
- **Clarity:** The "SDE" (Standardized Effect Size) row is a nice touch for comparability.
- **Storytelling:** Critical for the argument that implementation quality matters.
- **Labeling:** Good.
- **Recommendation:** **REVISE**
  - The "Control munis" count is 264 in every column. This is redundant. Move this to the table notes and only show "Treated Municipalities" in the rows to save space.

### Figure 4: "Event Study: Eradication Activity in PNIS Municipalities"
**Page:** 15
- **Formatting:** Green color choice distinguishes it from the primary outcome (coca area).
- **Clarity:** The x-axis only goes to 0 (the year of treatment). 
- **Storytelling:** This figure is meant to show if the *composition* of eradication changed. However, stopping at year 0 limits the story of the "mirage."
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - Extend the x-axis to +4 or +6, similar to Figure 1. If the "mirage" exists, we should see eradication activity drop off after the payment window (Year +1 or +2).

### Figure 5: "Dose-Response: Baseline Coca Intensity and Post-PNIS Cultivation"
**Page:** 16
- **Formatting:** Clean.
- **Clarity:** A bit cluttered with many dots.
- **Storytelling:** This is a more technical robustness check.
- **Labeling:** The y-axis label "Coefficient on Coca(2016) x Year" is very "econometrics-heavy."
- **Recommendation:** **MOVE TO APPENDIX**
  - The main text is becoming figure-heavy. This result (no dose-response) can be summarized in one sentence in the text.

### Figure 6: "Distribution of Coca Area Change in PNIS Municipalities, 2016–2020"
**Page:** 17
- **Formatting:** Professional histogram. 
- **Clarity:** The outlier at 20,000 hectares is extreme and compresses the rest of the distribution.
- **Storytelling:** Shows the "mix of compliers and reverters."
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - Use a "break" in the x-axis or a footnote for the extreme outlier to allow the distribution between -5000 and +5000 to be more visible.

### Table 4: "Summary of Robustness Checks"
**Page:** 20
- **Formatting:** Excellent "Summary Table" format often seen in top journals (e.g., AEJ).
- **Clarity:** Very high.
- **Storytelling:** Perfect way to wrap up the empirical section.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Table 5: "Standardized Effect Sizes"
**Page:** 25
- **Formatting:** The notes section is extremely long (a "mini-abstract").
- **Clarity:** Good.
- **Storytelling:** Useful for meta-analysis.
- **Labeling:** The "Classification" column (Moderate negative, etc.) is slightly subjective but helpful.
- **Recommendation:** **REVISE**
  - Shorten the table notes. Most of that information is in the main text. Focus notes on the calculation of SDE and the SE(SDE).

---

## Overall Assessment

- **Exhibit count:** 4 main tables, 6 main figures, 1 appendix table, 0 appendix figures.
- **General quality:** Extremely high. The paper follows the "modern DiD" visual standards (Sun-Abraham, event studies, robustness summaries).
- **Strongest exhibits:** Figure 1 (Event Study) and Table 4 (Robustness Summary).
- **Weakest exhibits:** Figure 2 (Scale issues) and Figure 5 (Too technical for main text).
- **Missing exhibits:** 
    - **Map of Colombia:** A paper about specific municipalities and "Waves" essentially requires a map showing treated vs. control areas and the Wave 1 vs. Wave 2 geography.
    - **Balance Table:** While Table 1 shows means, a formal balance table on pre-treatment covariates (if available, e.g., distance to markets, poverty index) would strengthen the parallel trends assumption.

**Top 3 improvements:**
1. **Add a Map:** This is the most glaring omission for a spatial development paper. Show the geography of the "mirage."
2. **Streamline Main Text Figures:** Move Figure 5 (Dose-Response) and possibly Figure 6 (Histogram) to the Appendix to keep the main text focused on the primary event study and heterogeneity.
3. **Fix Figure 2 Scale:** Use a log scale or indexed values (2016=100) to make the pre-trend comparison between PNIS and non-PNIS municipalities legible.