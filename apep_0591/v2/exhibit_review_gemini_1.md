# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-11T15:25:49.191440
**Route:** Direct Google API + PDF
**Tokens:** 18917 in / 2006 out
**Response SHA256:** 3cfce680853aa2fe

---

This review evaluates the visual exhibits of "The Erasmus Drain" for submission to top-tier economics journals.

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Figure 1: "Net Erasmus+ Outflows vs. Regional Development (NUTS3)"
**Page:** 6
- **Formatting:** Clean and professional. The red dashed line at zero is helpful.
- **Clarity:** Strong message, but the scatter plot is extremely dense (1,346 points). Individual points are hard to distinguish.
- **Storytelling:** Essential. It motivates the "Core vs. Periphery" tension.
- **Labeling:** Good. Includes region count and clear axis units.
- **Recommendation:** **REVISE**
  - Change to a **binscatter**. It would clean up the noise and make the negative slope more apparent while matching the style of Figures 2 and 3.

### Table 1: "Summary Statistics"
**Page:** 9
- **Formatting:** Professional three-line header. Proper use of panels (A and B). Numbers are not perfectly decimal-aligned (e.g., N column).
- **Clarity:** Excellent. Splitting by geographic resolution (NUTS3 vs NUTS2) is logical.
- **Storytelling:** Essential for understanding the variation in treatment and outcomes.
- **Labeling:** Clear. 
- **Recommendation:** **REVISE**
  - Decimal-align all columns.
  - Add a note explaining "pp" (percentage points) and "1k youth" explicitly to ensure no ambiguity.

### Table 2: "First Stage: Bartik Instrument and Erasmus Outflows"
**Page:** 13
- **Formatting:** Standard journal format. 
- **Clarity:** Good use of columns to show the "Go/No-Go" diagnostic across specifications. 
- **Storytelling:** Crucial for the paper's methodological contribution.
- **Labeling:** "Signif. Codes" is redundant if stars are defined in notes. 
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "First Stage: Bartik Instrument and Outflow Rate (NUTS3)"
**Page:** 14
- **Formatting:** Professional ggplot2 style. Confidence interval shaded correctly.
- **Clarity:** Clear binscatter. The negative relationship is easily visible.
- **Storytelling:** Supports Table 2 visually.
- **Labeling:** Y-axis title "(residualized)" is clear for an econometrics audience.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Main Results: Long-Difference Specifications"
**Page:** 15
- **Formatting:** Consistent with Table 2.
- **Clarity:** Mixing NUTS3 and NUTS2 in one table is slightly confusing. 
- **Storytelling:** This table is doing a lot of heavy lifting. It highlights the sign reversal between OLS and 2SLS.
- **Labeling:** Add "Instrumented by Bartik" to the footer to remind the reader of the IV.
- **Recommendation:** **REVISE**
  - Add the **First-stage F-statistic** to the "Fit statistics" section for all 2SLS columns (it's currently missing for col 2).

### Figure 3: "Reduced Form: Bartik Instrument and Youth Population Change"
**Page:** 16
- **Formatting:** Clean.
- **Clarity:** Excellent visual evidence of the raw correlation.
- **Storytelling:** Complements the 2SLS results in Table 3.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Supplementary: NUTS2 Panel Specifications"
**Page:** 17
- **Formatting:** Professional.
- **Clarity:** Shows the "death" of the result with country-year FE (Col 4) transparently.
- **Storytelling:** This is the "honest" table of the paper.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Distributed Lags: Addressing the Timing Mismatch"
**Page:** 18
- **Formatting:** Standard.
- **Clarity:** Logical progression from contemporaneous to 3-year lags.
- **Storytelling:** Vital for the "brain drain" vs. "temporary exchange" argument.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Placebo Test: Age-Specificity of Erasmus Effects"
**Page:** 19
- **Formatting:** Standard.
- **Clarity:** Good contrast between treatment group and placebo group.
- **Storytelling:** Crucial for the exclusion restriction/mechanism.
- **Recommendation:** **KEEP AS-IS** (But consider consolidating—see Table 7).

### Table 7: "Heterogeneity: Peripheral vs. Core Regions"
**Page:** 19
- **Formatting:** Professional.
- **Clarity:** Col 3 (Pooled) is the key takeaway.
- **Storytelling:** This is the most "AER-ready" table in the paper.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Placebo Test: Erasmus-Affected vs. Broader Cohort"
**Page:** 20
- **Formatting:** Coefficient plot. Clean.
- **Clarity:** Excellent. The point estimate for 25–64 hitting the zero-line is powerful.
- **Storytelling:** Redundant with Table 6 but much more effective for a presentation or 10-second skim.
- **Recommendation:** **KEEP AS-IS** (Consider removing Table 6 or moving it to Appendix).

### Figure 5: "Heterogeneity: Peripheral vs. Core Regions"
**Page:** 21
- **Formatting:** Consistent with Figure 4.
- **Clarity:** Very clear contrast.
- **Storytelling:** Redundant with Table 7 but essential for visual impact.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Receiver Side: Erasmus Inflows and Human Capital"
**Page:** 22
- **Formatting:** Binscatter. 
- **Clarity:** Shows the "null" result clearly.
- **Storytelling:** Supports the argument that gains are not symmetric.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Figure 7: "Randomization Inference Distribution"
**Page:** 29
- **Formatting:** Two-panel histogram.
- **Clarity:** The scale of the X-axis in the bottom panel (-75 to 25) makes the distribution look like a single line, making the "observed estimate" hard to see relative to the null.
- **Storytelling:** Essential robustness for shift-share IV.
- **Recommendation:** **REVISE**
  - Adjust X-axis limits for the NUTS3 panel so the distribution is actually visible. 

### Figure 8: "Leave-One-Country-Out Stability"
**Page:** 30
- **Formatting:** "Caterpillar" plot.
- **Clarity:** Excellent. Very standard for cross-country or EU studies.
- **Storytelling:** Proves no single country (like Italy or Turkey) drives the result.
- **Recommendation:** **KEEP AS-IS**

### Table 9: "Standardized Effect Sizes"
**Page:** 34
- **Formatting:** Basic.
- **Clarity:** Good for interpreting magnitude.
- **Storytelling:** Helpful, but could be integrated into the main text summary.
- **Recommendation:** **MOVE TO APPENDIX** (As already placed).

---

## Overall Assessment

- **Exhibit count:** 6 main tables, 6 main figures, 1 appendix table, 2 appendix figures.
- **General quality:** High. The paper follows the modern "Bartik/Shift-Share" style (Borusyak et al. 2022) with all necessary diagnostics (First stage, RI, Placebos).
- **Strongest exhibits:** Table 7 (Heterogeneity) and Figure 4 (Placebo coefficient plot).
- **Weakest exhibits:** Figure 1 (too cluttered) and Figure 7 (axis scaling issues).
- **Missing exhibits:** 
  1. **A Map:** For a paper on European NUTS regions, a heat map showing the "Bartik Predicted Outflow" intensity across Europe is almost mandatory for QJE/AER.
  2. **Rotemberg Weights Table:** While mentioned in the text (Section 7.1), a table showing the top 5-10 destinations and their weights/shocks is standard for shift-share papers.

- **Top 3 improvements:**
  1. **Add a geographic map** of the instrument intensity. It grounds the "Core vs. Periphery" story in actual geography.
  2. **Convert Figure 1 to a binscatter.** The current cloud of 1,300 points obscures the relationship.
  3. **Consolidate Table 6 into Figure 4.** Figure 4 tells the placebo story better. You can report the coefficients in the text or a combined robustness table to save space.