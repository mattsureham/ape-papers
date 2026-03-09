# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-09T13:25:32.402006
**Route:** Direct Google API + PDF
**Tokens:** 17877 in / 1817 out
**Response SHA256:** 1b1865f4bf0051b7

---

This review evaluates the exhibits of "Much Ado About Markets: Null Effects of India’s Farm Laws on Retail Commodity Prices" for submission to top-tier economics journals.

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics"
**Page:** 10
- **Formatting:** Needs work. Currently uses a non-standard layout for Panel A and B. The font size for the numbers appears smaller than the text.
- **Clarity:** Logically organized by "Phase" and "APMC Intensity," which matches the paper's identification. However, the horizontal layout is cramped.
- **Storytelling:** Strong. It immediately shows that High/Low APMC states have similar price levels, which foreshadows the null result.
- **Labeling:** Good. Includes units (INR/kg) and explains the groups in the notes.
- **Recommendation:** **REVISE**
  - Use a standard `booktabs` format (top, middle, bottom rules only).
  - Align numbers by decimal point. 
  - Separate Panel A and B with more vertical whitespace. 
  - Change "N" to "Observations" for clarity.

### Table 2: "Effect of Farm Laws on Agricultural Commodity Prices"
**Page:** 13
- **Formatting:** Standard journal format. No vertical lines.
- **Clarity:** Clear columns for different specifications.
- **Storytelling:** This is the core table. It effectively shows the null across five different outcomes/measures.
- **Labeling:** Good notes. Significance stars defined. SEs in parentheses.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Event Study: Price Effect by APMC Stringency"
**Page:** 14
- **Formatting:** High quality. Clean background (minimal gridlines).
- **Clarity:** The "spikes" in the pre-treatment period (around month -15) are visually distracting but accurately reflect the data. 
- **Storytelling:** The shaded "ON phase" region is an excellent visual aid for the "symmetric" design.
- **Labeling:** The y-axis label $\hat{\beta}_t$ is technical; consider "Coefficient on APMC Stringency" for a general reader.
- **Recommendation:** **REVISE**
  - Add a horizontal dashed line at 0 for easier visual reference.
  - The "Pre-treatment", "ON phase", and "OFF phase" labels are great; keep them.

### Figure 2: "Retail Commodity Prices by APMC Regulation Intensity"
**Page:** 15
- **Formatting:** Professional. Use of color is distinguishable (Red vs Blue).
- **Clarity:** The confidence bands are a bit "messy" due to the 2019 price spike.
- **Storytelling:** Essential for showing parallel trends in levels.
- **Labeling:** Clear legend. Date labels on x-axis are appropriate.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Symmetric Test: ON-Phase vs. OFF-Phase Coefficients"
**Page:** 16
- **Formatting:** Clean.
- **Clarity:** Highly readable. The juxtaposition of ON and OFF for two different measures is clear.
- **Storytelling:** This is the "money shot" of the paper's identification strategy. 
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Robustness Checks"
**Page:** 16
- **Formatting:** Minimalist.
- **Clarity:** Very easy to read.
- **Storytelling:** Provides the necessary "peace of mind" for a reader concerned about specific states (Punjab/Haryana).
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Leave-One-State-Out: ON-Phase Estimates"
**Page:** 17
- **Formatting:** Standard "forest plot" style.
- **Clarity:** Excellent. The states are ordered, which is helpful.
- **Storytelling:** Directly addresses concerns about outliers (like Punjab) driving the null.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Placebo Tests"
**Page:** 17
- **Formatting:** A bit sparse.
- **Clarity:** The use of "—" for Bihar/Blocked states (because they aren't "interacted" in the same way) is slightly confusing without reading the notes.
- **Storytelling:** Strong. Shows that a "fake" treatment looks just like the "real" one.
- **Recommendation:** **REVISE**
  - Instead of "—", consider putting the specific coefficient from those subsamples or clearly labeling the rows "Bihar Baseline" etc.

### Figure 5: "Randomization Inference: Distribution Under Sharp Null"
**Page:** 18
- **Formatting:** Good. Standard RI histogram.
- **Clarity:** Clear red line for the actual estimate.
- **Storytelling:** Critical for a null-result paper to show that the result isn't just a lack of power but a true zero.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Heterogeneous Effects by Commodity"
**Page:** 19
- **Formatting:** Standard.
- **Clarity:** Logical grouping.
- **Storytelling:** Necessary to show the null isn't being masked by one massive outlier commodity.
- **Recommendation:** **MOVE TO APPENDIX**
  - Figure 6 (below) tells this exact story more effectively. Main text only needs one.

### Figure 6: "Heterogeneous Price Effects by Commodity"
**Page:** 19
- **Formatting:** Clean.
- **Clarity:** Clear distinction between ON/OFF phases across 5 commodities.
- **Storytelling:** Much better than Table 5. Visualizes the uncertainty and the consistency of the null.
- **Recommendation:** **KEEP AS-IS**

### Figure 7: "State-Level APMC Regulation Intensity"
**Page:** 20
- **Formatting:** Professional bar chart.
- **Clarity:** The color coding for "Blocked" vs "Implemented" is a great detail.
- **Storytelling:** This "Data" figure is vital for understanding the treatment variation.
- **Recommendation:** **PROMOTE TO MAIN TEXT** (Move it from the "Discussion" section to the "Data" or "Institutional Background" section).

---

## Appendix Exhibits

### Table 6: "APMC Stringency Index: Selected States"
**Page:** 29
- **Formatting:** Standard.
- **Recommendation:** **KEEP AS-IS**

### Table 7: "Variable Definitions"
**Page:** 29
- **Formatting:** Table is a bit long.
- **Recommendation:** **KEEP AS-IS** (Standard for AEJ/AER papers).

### Table 8: "Standardized Effect Sizes for Main Outcomes"
**Page:** 32
- **Formatting:** Dense notes.
- **Storytelling:** For a null result, SDEs are a "Reviewer 2" favorite.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 3 main tables, 7 main figures, 3 appendix tables, 0 appendix figures.
- **General quality:** Extremely high. The paper uses modern "visual causal inference" (event studies, permutation distributions, leave-one-out) very well.
- **Strongest exhibits:** Figure 1 (Event Study) and Figure 5 (Randomization Inference).
- **Weakest exhibits:** Table 1 (needs alignment/formatting) and Table 5 (redundant with Figure 6).
- **Missing exhibits:** A **Map of India** shaded by APMC Stringency Index. This is standard in "top-5" development papers (QJE/AER) to show geographic clustering (or lack thereof) of treatment.
- **Top 3 improvements:**
  1. **Add a Map:** Visualize the APMC Stringency Index across India's geography.
  2. **Consolidate Heterogeneity:** Use Figure 6 in the main text and move Table 5 to the appendix to reduce clutter.
  3. **Professionalize Table 1:** Decimal-align numbers and use standard LaTeX `booktabs` formatting to meet AER/QJE aesthetic standards.