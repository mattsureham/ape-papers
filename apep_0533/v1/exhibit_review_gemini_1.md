# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-05T20:19:58.069282
**Route:** Direct Google API + PDF
**Tokens:** 17877 in / 1784 out
**Response SHA256:** c231b3414685c361

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Pre-Treatment Means"
**Page:** 10
- **Formatting:** Clean and professional. Good use of horizontal rules (booktabs style).
- **Clarity:** Very high. The comparison between Ban and Non-Ban states is intuitive.
- **Storytelling:** Essential. It establishes that "levels" were similar before treatment, supporting the parallel trends assumption.
- **Labeling:** Clear. Units (millions, per quarter) are included.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Effect of Salary History Bans on Gender Earnings Ratio"
**Page:** 15
- **Formatting:** Standard "stargazer" or "modelsummary" output. Professional, but the "period:new_hire" row label is a bit "codery." 
- **Clarity:** Good. It clearly shows the simple DiD and the DDD.
- **Storytelling:** This is the central table of the paper.
- **Labeling:** Good. Significance stars and SE notes are present.
- **Recommendation:** **REVISE**
  - Change row label "period:new_hire" to "Quarter $\times$ New Hire FE" to match academic conventions.
  - In the "Dependent Variables" header, replace raw variable names (e.g., `log_ratio_hir`) with descriptive text (e.g., "Log Ratio (New Hires)").

### Figure 1: "Event Study: Gender Earnings Ratio by Worker Type"
**Page:** 16
- **Formatting:** Modern ggplot style. The overlapping shaded CIs are a bit "busy" but standard for CS-DiD plots.
- **Clarity:** The message (flat pre-trends, null post-effect) is clear. However, the light blue and red shading overlap significantly between event time -5 and 5, making it hard to distinguish the two.
- **Storytelling:** Vital for validating the research design.
- **Labeling:** Y-axis and X-axis are well-labeled.
- **Recommendation:** **REVISE**
  - Use different line patterns (e.g., solid vs. dashed) in addition to colors to help distinguish the two groups where they overlap.
  - Consider a "hollow" or "hatched" error bar style for one of the groups to improve transparency.

### Table 3: "Callaway-Sant’Anna Group-Time ATT Estimates"
**Page:** 17
- **Formatting:** Minimalist.
- **Clarity:** Low. It presents only two numbers in a large table.
- **Storytelling:** Redundant. These numbers are already mentioned in the text and visualized in Figure 1.
- **Labeling:** Sufficient.
- **Recommendation:** **MOVE TO APPENDIX** or **REMOVE**. These coefficients could easily be added as a row to Table 2 or just left in the text.

### Table 4: "Decomposition: Female vs. Male New Hire Earnings and Hiring Composition"
**Page:** 18
- **Formatting:** Consistent with Table 2.
- **Clarity:** High. Separating the numerator and denominator of the ratio explains *why* the ratio didn't move.
- **Storytelling:** Critical "mechanism" check.
- **Labeling:** "log_earn_f_hir" should be renamed to "Log Female Earnings" for the final version.
- **Recommendation:** **REVISE**
  - Clean up the variable headers to remove underscores.

### Figure 2: "Industry Heterogeneity: Effect on New-Hire Gender Earnings Ratio"
**Page:** 19
- **Formatting:** Good forest plot.
- **Clarity:** Excellent. The color-coding by industry type (Male-Dominated vs. Female-Dominated) is very helpful.
- **Storytelling:** Strong. It shows the null isn't just an average of offsetting large effects.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Heterogeneity by Industry Gender Composition"
**Page:** 20
- **Formatting:** Consistent.
- **Clarity:** Good.
- **Storytelling:** This provides the statistical "teeth" to Figure 2.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS** (Though consider merging into a single "Heterogeneity" table with Table 4 to save space).

### Figure 3: "Randomization Inference: Distribution of Placebo Treatment Effects"
**Page:** 21
- **Formatting:** Standard histogram.
- **Clarity:** High. The vertical dashed line clearly shows where the actual estimate sits.
- **Storytelling:** Important for a "null result" paper to prove the result isn't due to clustered SE issues.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Robustness Checks"
**Page:** 22
- **Formatting:** A bit cramped.
- **Clarity:** This table is a "summary" table of other tables. It's a bit redundant.
- **Storytelling:** It serves as a "one-stop-shop" for robustness, but many of these results are already in Tables 3, 4, and 5.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**. Main text readers prefer seeing the full specifications in earlier tables.

---

## Appendix Exhibits

### Table 7: "Salary History Ban Effective Dates and Treatment Coding"
**Page:** 30
- **Formatting:** Clean list.
- **Clarity:** High.
- **Storytelling:** Necessary for replicability.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Raw Trends: Gender Earnings Ratio by Treatment Group"
**Page:** 31
- **Formatting:** Panels A and B are clear.
- **Clarity:** The "sawtooth" seasonal pattern is very prominent.
- **Storytelling:** Excellent. It shows the "raw" data before the DiD machinery is applied.
- **Recommendation:** **PROMOTE TO MAIN TEXT**. Top journals (AER/QJE) increasingly demand seeing the raw data trends early in the paper. This should follow Figure 1 or be Figure 1.

### Figure 5: "Staggered Treatment Adoption"
**Page:** 32
- **Formatting:** Clean timeline plot.
- **Clarity:** High.
- **Storytelling:** Standard for staggered DiD.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS** (in Appendix)

---

## Overall Assessment

- **Exhibit count:** 5 main tables (excluding the ones I suggested moving), 3 main figures, 2 appendix tables, 2 appendix figures.
- **General quality:** High. The paper follows modern "Causal Inference" visual standards (Event studies, RI plots, Forest plots).
- **Strongest exhibits:** Figure 2 (Industry Forest Plot) and Figure 3 (Randomization Inference).
- **Weakest exhibits:** Table 3 (Redundant) and Table 6 (Redundant summary).
- **Missing exhibits:** A **Map of the US** showing treated vs. untreated states is a standard "Exhibit 1" in most state-level policy papers and would help with the "Legislative Wave" section.

**Top 3 improvements:**
1.  **Consolidate/Streamline Tables:** Tables 3 and 6 are largely redundant. Merge the key point-estimates into Table 2 or move them entirely to the Appendix to keep the main text lean.
2.  **Visual Clarity in Figure 1:** The overlapping confidence intervals are the most important visual proof of the null. Use transparency (alpha), hatching, or offset the x-axis slightly for the two groups (jittering) so the error bars don't "muddy" each other.
3.  **Promote Figure 4:** Move the raw trends to the main text. It builds significant trust in the research design to see the seasonality and the tight tracking of the two groups in the raw data.