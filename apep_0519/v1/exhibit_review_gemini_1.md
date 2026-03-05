# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-05T13:17:21.641419
**Route:** Direct Google API + PDF
**Tokens:** 19957 in / 2015 out
**Response SHA256:** 5f738fb211e49d0e

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Heating Systems by Treatment Status"
**Page:** 11
- **Formatting:** High quality. Clean booktabs style with proper use of horizontal rules and grouping of panels (A and B).
- **Clarity:** Very good. Clearly delineates the difference between the pre-treatment and post-treatment periods.
- **Storytelling:** Essential. It immediately validates the paper's claim that both groups are trending upward significantly, making the DiD approach necessary.
- **Labeling:** Professional. Notes are descriptive.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Heat Pump Share Trends by MuKEn 2014 Adoption Cohort"
**Page:** 21
- **Formatting:** Modern and clean. The use of dashed lines to bridge the data gap is a standard and effective choice for this identification challenge.
- **Clarity:** Excellent. The 10-second takeaway is that all cohorts have parallel slopes, which is the primary "visual test" for any DiD paper.
- **Storytelling:** This is the most important figure in the paper. It visualizes the parallel trends assumption and the massive secular trend that dwarfs the treatment effect.
- **Labeling:** Clear. Legend is well-positioned.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Long-Difference: Heat Pump Share Change versus MuKEn Exposure"
**Page:** 22
- **Formatting:** Standard scatter with OLS fit. The use of cantonal abbreviations (AG, ZH, etc.) is helpful for Swiss readers but might need a reference for international journals.
- **Clarity:** The flat blue line reinforces the null result clearly.
- **Storytelling:** This provides a robustness check against the staggered timing issues by collapsing the time dimension.
- **Labeling:** Clear y-axis label (percentage points).
- **Recommendation:** **REVISE**
  - Add a note or a legend entry for the "95% confidence band" (though it is in the notes, a visual legend entry for the shaded area is standard).
  - Ensure the y-axis (Change in pp) is consistent with how results are reported in the text (0-1 scale vs. pp).

### Figure 3: "TWFE Coefficient Estimates Across Outcome Variables"
**Page:** 23
- **Formatting:** Clean forest plot. Good use of color to distinguish significance.
- **Clarity:** Very high. One can immediately see that only fossil, gas, and wood are significant (and negative).
- **Storytelling:** This is the "summary of results" figure. It makes Table 2 much easier to digest.
- **Labeling:** Horizontal axis is clear.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Effect of MuKEn 2014 Adoption on Heating System Shares"
**Page:** 16
- **Formatting:** Standard journal format. No vertical lines.
- **Clarity:** Logical progression from the main outcome (HP Share) to the drivers (Oil, Gas) and the placebo (Wood).
- **Storytelling:** The core results table.
- **Labeling:** Good. Significance stars are standard.
- **Recommendation:** **REVISE**
  - **Decimal Alignment:** Align the coefficients and standard errors by the decimal point. Currently, they are centered, which makes comparing magnitudes across columns harder.
  - **Note:** Explicitly state that "Standard errors are clustered at the canton level" in the table notes (which it does, but make sure the font size is consistent with AER/QJE styles).

### Table 3: "Extended Specifications: Treatment Intensity, Surface Area, and Long-Difference"
**Page:** 17
- **Formatting:** Grouped by panels, which is efficient.
- **Clarity:** High. Distinguishes between the primary outcome (counts) and the intensive margin (surface area).
- **Storytelling:** Consolidates multiple robustness checks into one exhibit.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Sun-Abraham Heterogeneity-Robust Estimates"
**Page:** 19
- **Formatting:** Professional side-by-side comparison of the traditional and robust estimators.
- **Clarity:** Very high.
- **Storytelling:** Essential for modern applied micro papers to address staggered treatment timing.
- **Labeling:** Detailed notes on the Sun-Abraham implementation.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Table 5: "Bacon Decomposition of TWFE Estimate"
**Page:** 32
- **Formatting:** Simple and clean.
- **Clarity:** Shows exactly where the identifying weight is coming from.
- **Storytelling:** Supports the validity of the TWFE results.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Robustness of Inference: Alternative Approaches"
**Page:** 33
- **Formatting:** Clear comparison.
- **Clarity:** Easy to see that p-values are robust across methods.
- **Storytelling:** Necessary for papers with a small number of clusters (26 cantons).
- **Recommendation:** **KEEP AS-IS**

### Table 7: "Sensitivity to Excluding 2022 (Energy Crisis Year)"
**Page:** 33
- **Formatting:** Side-by-side columns are the right choice here.
- **Clarity:** High.
- **Storytelling:** Addresses a major potential confounder.
- **Recommendation:** **KEEP AS-IS**

### Table 8: "Placebo Tests: Non-Targeted Outcomes"
**Page:** 34
- **Formatting:** Clean.
- **Clarity:** High.
- **Storytelling:** This table is actually quite important because it highlights the "Wood share" problem. 
- **Recommendation:** **MOVE TO MAIN TEXT** (or consolidate with Table 2). The "Wood share" result is a central part of the paper's skepticism about the causal identification; it shouldn't be hidden in the appendix.

### Figure 4: "MuKEn 2014 Adoption Timeline by Canton"
**Page:** 34
- **Formatting:** Gantt-style chart. Very effective for showing treatment variation.
- **Clarity:** High.
- **Storytelling:** Explains the "staggered" nature of the design.
- **Recommendation:** **PROMOTE TO MAIN TEXT.** Top journals (AER/QJE) often include a "treatment timing" figure early in the paper to establish the source of variation.

### Figure 5: "Heat Pump Surface Share by Canton, 2021–2023"
**Page:** 35
- **Formatting:** Spaghetti plot. A bit cluttered.
- **Clarity:** Hard to follow individual cantons, but the overall upward trend is visible.
- **Storytelling:** Supports the "dose-response" finding in Table 3.
- **Recommendation:** **REVISE**
  - Use thicker lines or highlight 2-3 representative cantons (e.g., an early adopter, a late adopter, and the control).
  - The legend is quite large and takes up significant space; consider moving it to the side or thinning the entries.

### Table 9: "MuKEn 2014 Adoption Timeline by Canton"
**Page:** 36
- **Formatting:** Simple list.
- **Clarity:** High.
- **Storytelling:** Reference material.
- **Recommendation:** **KEEP AS-IS** (Leave in Appendix).

---

## Overall Assessment

- **Exhibit count:** 3 main tables, 3 main figures, 6 appendix tables, 2 appendix figures.
- **General quality:** Extremely high. The paper follows the modern "gold standard" for DiD papers (Sun-Abraham, Bacon decomposition, wild cluster bootstrap). The visuals are clean, minimalist, and use a consistent color palette.
- **Strongest exhibits:** Figure 1 (Parallel Trends) and Table 4 (Sun-Abraham comparison).
- **Weakest exhibits:** Figure 5 (Spaghetti plot is hard to read) and Table 8 (is too important to be in the appendix).

**Missing exhibits:**
- **Event Study Figure:** While Figure 1 shows the raw data, a formal **Event Study Plot** (coefficients by lead/lag) is almost mandatory for QJE/AER. Even with the 2016-2020 data gap, you should plot the coefficients for the available years to show no pre-trends in coefficient space.

**Top 3 improvements:**
1. **Add an Event Study Figure:** Use the Sun-Abraham coefficients to plot the treatment effect by year relative to adoption. This is the "money shot" for most DiD papers.
2. **Promote Figure 4 (Adoption Timeline):** Move this to Section 2 or 3 of the main text. It provides the institutional foundation for the entire identification strategy.
3. **Decimal Alignment:** Fix the formatting in Table 2 and Table 4 to decimal-align all numbers. This is a small but necessary step for "A-journal" professionalism.