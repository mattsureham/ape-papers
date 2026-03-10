# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-10T11:06:36.676436
**Route:** Direct Google API + PDF
**Tokens:** 19437 in / 1872 out
**Response SHA256:** 810acc12dc99f6b7

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Pre-Treatment Municipality Characteristics"
**Page:** 10
- **Formatting:** Generally clean. Uses horizontal rules correctly. Number alignment is slightly off; the "Difference" column should be decimal-aligned.
- **Clarity:** High. Groups variables logically. The distinction between levels (Population) and shares (%) is clear.
- **Storytelling:** Essential. Establishes the fundamental differences between treated and control groups (treated are smaller, higher second-home stock).
- **Labeling:** Good. Notes explain the different time windows for vacancy vs. employment data.
- **Recommendation:** **KEEP AS-IS** (with minor decimal alignment tweak).

### Figure 1: "Vacancy Rates in Treated vs. Control Municipalities, 1995–2025"
**Page:** 14
- **Formatting:** Professional. Use of solid/dashed lines and colors is distinct. Shaded confidence bands are visible but not overwhelming.
- **Clarity:** The key message (divergence post-2013) is clear, though the pre-2000 volatility is a bit distracting.
- **Storytelling:** Strong. Shows the parallel trends and the gradual nature of the treatment effect.
- **Labeling:** Clear. The "Initiative adopted" vertical line is helpful.
- **Recommendation:** **REVISE**
  - Add a note or label explaining the 2018-2020 "hump" seen in both groups (likely a macro-level Swiss housing trend) to pre-empt reviewer questions about common shocks.

### Figure 2: "Event Study: Effect of Lex Weber on Municipal Vacancy Rates"
**Page:** 15
- **Formatting:** Standard for top-tier journals. Clear zero line.
- **Clarity:** Excellent. The reference period is clearly marked. The gradual decline matches the "construction pipeline" narrative.
- **Storytelling:** This is the most important figure in the paper. It proves parallel trends and shows the dynamic effect.
- **Labeling:** Proper axis labels and notes on clustering.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Effect of the Second Homes Initiative on Municipal Outcomes"
**Page:** 16
- **Formatting:** Standard AER format. Decimal alignment is good.
- **Clarity:** Very clean. Presenting the four primary outcomes in one table allows for easy comparison of magnitudes.
- **Storytelling:** Central table. It connects the vacancy effect to population and employment declines.
- **Labeling:** Notes are comprehensive. Significance stars are defined.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Regression Discontinuity Estimates at the 20% Second-Home Threshold"
**Page:** 17
- **Formatting:** Clean. Includes necessary RD diagnostics (Bandwidth, Eff. N).
- **Clarity:** Good. It is clear that these results are statistically insignificant compared to the DiD.
- **Storytelling:** Important for honesty. It shows the RDD is underpowered but carries the same sign as the DiD.
- **Labeling:** Detailed notes on the kernel and CI type.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Regression Discontinuity: Vacancy Rates at the 20% Second-Home Threshold"
**Page:** 17
- **Formatting:** Standard RD plot. The binned scatter points are clear.
- **Clarity:** The "flatness" of the discontinuity confirms the Table 3 result.
- **Storytelling:** Visually confirms why the RDD is null: high variance near the cutoff and a small "jump."
- **Labeling:** Y-axis clearly labeled as "Post-Treatment."
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Mechanism: Sectoral Employment Effects of the Lex Weber"
**Page:** 19
- **Formatting:** Clean coefficient plot. 
- **Clarity:** Very high. One can immediately see that the effect is driven by the Secondary sector.
- **Storytelling:** Excellent. It provides the "smoking gun" for the construction mechanism.
- **Labeling:** Axis labels are clear.
- **Recommendation:** **KEEP AS-IS** (Though could be combined with Figure 5 into a "Mechanisms and Heterogeneity" multi-panel figure).

### Table 4: "Sectoral Employment Effects of the Second Homes Initiative"
**Page:** 19
- **Formatting:** Redundant with Figure 4. 
- **Clarity:** Clear, but adds little new information over the figure.
- **Storytelling:** Consolidates the employment story.
- **Labeling:** Good.
- **Recommendation:** **MOVE TO APPENDIX** (Keep Figure 4 in the main text; top journals prefer the visual representation of coefficients for mechanisms).

### Figure 5: "Heterogeneity: Vacancy Rate Effects by Tourism Intensity"
**Page:** 21
- **Formatting:** Consistent with Figure 4.
- **Clarity:** Good.
- **Storytelling:** Important for the "dose-response" argument.
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - Merge this with Figure 4 as Panel B, or create a single "Heterogeneity" figure that includes the Language and Treatment Intensity splits mentioned in the text but currently missing as figures.

---

## Appendix Exhibits

### Figure 6: "Event Study: Effect of Lex Weber on Log Population"
**Page:** 30
- **Recommendation:** **PROMOTE TO MAIN TEXT**. Population decline is a major claim in the abstract. Seeing the dynamic evidence for it is as important as the vacancy event study. Place it after Figure 2.

### Table 5: "Placebo Timing Tests"
**Page:** 31
- **Recommendation:** **KEEP AS-IS** (Standard robustness).

### Table 6: "Additional Robustness Checks for Vacancy Rate DiD"
**Page:** 31
- **Recommendation:** **KEEP AS-IS**. Excellent summary table that saves the reader from flipping through five different pages.

### Figure 7: "Leave-One-Canton-Out: Stability of Main Estimate"
**Page:** 32
- **Recommendation:** **KEEP AS-IS**.

### Figure 8: "Randomization Inference: Distribution of Placebo Estimates"
**Page:** 33
- **Recommendation:** **KEEP AS-IS**.

### Table 7: "Heterogeneity in Vacancy Rate Effects"
**Page:** 34
- **Recommendation:** **PROMOTE TO MAIN TEXT**. The text relies heavily on these "dose-response" results to rule out confounding. This is too central for the appendix.

### Table 8: "Standardized Effect Sizes for Main Outcomes"
**Page:** 35
- **Recommendation:** **REMOVE**. While helpful for the author, top journals rarely include a "self-interpretation" table of effect sizes. This information should be in the text of the Results section.

---

## Overall Assessment

- **Exhibit count:** 4 Main Tables, 5 Main Figures, 4 Appendix Tables, 3 Appendix Figures.
- **General quality:** Extremely high. The exhibits follow the "minimalist" aesthetic of the QJE/AER. 
- **Strongest exhibits:** Figure 2 (Event Study) and Figure 4 (Sectoral Employment). They tell the causal story and the mechanism story perfectly.
- **Weakest exhibits:** Table 8 (redundant) and Figure 1 (the raw data is a bit noisy for a main text figure, though necessary for transparency).
- **Missing exhibits:** 
  1. **Map of Treatment:** A map of Switzerland showing treated vs. control municipalities would be highly impactful for a geography-based paper.
  2. **Binscatter of Dose-Response:** A figure showing the change in vacancy rate (Post minus Pre) on the Y-axis against the continuous second-home share on the X-axis would reinforce the "Intensity" argument visually.

- **Top 3 improvements:**
  1. **Promote the Population Event Study (Fig 6) and the Heterogeneity Table (Table 7)** to the main text. They are too central to be "relegated" to the appendix.
  2. **Add a geographic map** showing the "Alpine Arc" of treatment. This grounds the "landscape protection" narrative.
  3. **Decimal-align all tables.** In Table 1 and Table 2, ensure the periods in the numbers line up vertically to improve readability of magnitudes.