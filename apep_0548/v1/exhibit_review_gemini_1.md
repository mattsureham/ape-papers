# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-09T11:02:14.374377
**Route:** Direct Google API + PDF
**Tokens:** 19957 in / 1885 out
**Response SHA256:** 30699f657a3dac08

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Figure 1: "Selective Licensing Adoption Across English Local Authorities"
**Page:** 10
- **Formatting:** Clean, but the dual-axis (Count vs. Cumulative) can be tricky. The font sizes for axes are a bit small compared to the header.
- **Clarity:** Excellent. The bars for annual and the line for cumulative clearly show the 2015 "acceleration" mentioned in the text.
- **Storytelling:** Essential. It justifies the use of a staggered DiD design.
- **Labeling:** Good. "Year" and "Count" are clear.
- **Recommendation:** **KEEP AS-IS**

### Table 1: "Summary Statistics"
**Page:** 11
- **Formatting:** Numbers are not decimal-aligned. For example, "12.372" and "350" in the first column should be aligned by the decimal point (or right-aligned if units differ). 
- **Clarity:** Logical grouping. Splitting by "Never Licensed" vs "Ever Licensed" immediately reveals the selection issue (cheaper houses in treated areas).
- **Storytelling:** Strong. It sets up the "selection into treatment" discussion.
- **Labeling:** The note is very thorough. 
- **Recommendation:** **REVISE**
  - Decimal-align all numeric values. 
  - Add a "Difference" column with a t-test for mean differences to formally show the selection bias.

### Figure 2: "Event Study: Callaway–Sant’Anna Estimates"
**Page:** 15
- **Formatting:** Modern look. The shaded 95% CI is professional.
- **Clarity:** The message—no pre-trend and a gradual negative drift—is clear. However, the y-axis spans -0.15 to 0.05; the zero line is dashed but could be more prominent.
- **Storytelling:** This is the "money plot" of the paper, showing the reversal of the TWFE result.
- **Labeling:** Clear. 
- **Recommendation:** **REVISE**
  - Increase the line weight of the zero-horizontal line to make the "null effect" visually more immediate.
  - Add the joint Wald test p-value for pre-trends (p=0.15) directly onto the "Pre-treatment" side of the plot area.

### Figure 3: "Event Study: Sun–Abraham Interaction-Weighted Estimates"
**Page:** 16
- **Formatting:** Similar to Figure 2 but uses a different color (red). 
- **Clarity:** The long-horizon pre-trends (relative years -19 to -6) are very noisy and distract from the main window.
- **Storytelling:** It confirms the CS-DiD results.
- **Recommendation:** **REVISE**
  - Crop the x-axis to match Figure 2 (e.g., -5 to +8). The noise at year -19 adds no value and makes the relevant window harder to see. 

### Table 2: "Effect of Selective Licensing on Property Prices"
**Page:** 17
- **Formatting:** Journal-ready. Use of "–" for excluded FEs is standard.
- **Clarity:** Very clean. Three columns (TWFE, TWFE+Controls, CS-DiD) show the sign reversal perfectly.
- **Storytelling:** This is the core table. 
- **Labeling:** "Standard errors clustered at the LA level in parentheses" is good.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Treatment Effect by PRS Exposure"
**Page:** 18
- **Formatting:** Standard "coefficient plot" style.
- **Clarity:** The comparison between the "Continuous dose" and the splits is clear.
- **Storytelling:** Critical for the mechanism.
- **Recommendation:** **REVISE**
  - The "Continuous dose" coefficient (-0.202) is on a different scale/meaning than the subsample means. I recommend removing the "Continuous dose" from this specific forest plot and moving it to its own table or mentioning it in text, as plotting it alongside "Low-PRS" and "High-PRS" point estimates is a category error for a reader.

### Figure 5: "Randomization Inference"
**Page:** 19
- **Formatting:** Professional. Red line for the actual estimate is a standard "top journal" look.
- **Clarity:** Instantly shows the 3.9% result is an outlier.
- **Storytelling:** Provides the frequentist robustness needed for these types of papers.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Leave-One-Out Sensitivity"
**Page:** 20
- **Formatting:** Clean.
- **Clarity:** Shows the result isn't driven by London or Burnley specifically.
- **Storytelling:** Standard robustness.
- **Recommendation:** **MOVE TO APPENDIX** (This is a "sanity check" that rarely stays in a 40-page main text for AER/QJE).

### Table 3: "Alternative Time Windows"
**Page:** 21
- **Formatting:** Simple.
- **Clarity:** High.
- **Storytelling:** Shows the result is a long-term trend, not a shock.
- **Recommendation:** **MOVE TO APPENDIX** (The text summary on page 20 is sufficient for the main body).

### Figure 7: "Treatment Effect by Property Composition"
**Page:** 21
- **Formatting:** Identical to Figure 4.
- **Clarity:** Good.
- **Storytelling:** Redundant with Figure 4/Mechanism section. 
- **Recommendation:** **REMOVE** (The paper already establishes the PRS mechanism; splitting by "flats" is just a proxy for PRS. Figure 9 in the appendix already covers this).

### Figure 8: "Raw Price Trends: Licensed vs. Non-Licensed Local Authorities"
**Page:** 22
- **Formatting:** Excellent. Use of shaded bands for CIs is standard.
- **Clarity:** High.
- **Storytelling:** Essential "Figure 1" or "Figure 2" for any DiD paper.
- **Recommendation:** **KEEP AS-IS** (But consider moving earlier in the paper, before the regression results).

---

## Appendix Exhibits

### Table 4: "Variable Definitions"
**Page:** 32
- **Formatting:** Good.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Implied Treatment Effect by PRS Share"
**Page:** 34
- **Formatting:** Clear.
- **Storytelling:** Very helpful for interpreting the dose-response.
- **Recommendation:** **PROMOTE TO MAIN TEXT** (This makes the mechanism result in Section 6.4 much more concrete).

### Figure 9: "Treatment Effect by Property Composition (Appendix)"
**Page:** 35
- **Recommendation:** **KEEP AS-IS** (Since I recommended removing Figure 7 from the main text, this should stay here).

### Table 6: "Standardized Effect Sizes for Main Outcomes"
**Page:** 36
- **Formatting:** Very "medical journal" style, but helpful for meta-analysis.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 2 main tables, 6 main figures, 4 appendix tables, 1 appendix figure
- **General quality:** High. The paper follows the "modern DiD" template perfectly (Raw trends → Adoption timeline → Event Study → Robustness).
- **Strongest exhibits:** Figure 2 (Event Study) and Table 2 (Main Results).
- **Weakest exhibits:** Figure 3 (needs cropping) and Figure 7 (redundant).
- **Missing exhibits:** A **map** of England showing treated local authorities would be standard for a QJE/AER paper to show geographic clustering (North vs. London).

**Top 3 improvements:**
1. **Map:** Add a map of England highlighting the 52 treated local authorities to visualize the "North-South" divide mentioned in the text.
2. **Crop Figure 3:** Remove the noisy pre-period (years -19 to -6) to focus the reader's eye on the parallel trends test.
3. **Consolidate/Streamline:** Move the Leave-one-out and Time Window exhibits to the appendix to keep the main text focused on the TWFE vs. CS-DiD divergence.