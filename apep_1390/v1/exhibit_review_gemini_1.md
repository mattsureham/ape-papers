# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-04-07T21:00:48.224611
**Route:** Direct Google API + PDF
**Tokens:** 16837 in / 1917 out
**Response SHA256:** c1586549ae4c5d1d

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics by Treatment Group"
**Page:** 8
- **Formatting:** Clean and professional. The use of grouped column headers for "Participating" vs. "Non-Participating" is excellent.
- **Clarity:** Very high. The level differences between the two groups are immediately obvious, justifying the DDD approach.
- **Storytelling:** Essential. It sets the stage for the identification strategy by showing that while levels differ, the groups are comparable enough for a trends-based analysis.
- **Labeling:** Clear. Units are specified ($1950, years, percentages).
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Sheppard-Towner Exposure and Long-Run Outcomes: Triple-Difference Estimates"
**Page:** 11
- **Formatting:** Generally good, but the variable name `I(I(age_1950ˆ2))` is "leaking" raw code. It should be labeled "Age Squared." Decimal alignment is good.
- **Clarity:** The table is a bit dense. The inclusion of "Varying Slopes" as a row with a single "Yes" in Column 3 is slightly awkward.
- **Storytelling:** This is the core table of the paper. It effectively shows the "Health Productivity" fingerprint (positive wages, zero education/occ score).
- **Labeling:** Comprehensive. Significance stars and clustering are well-noted.
- **Recommendation:** **REVISE**
  - Rename `I(I(age_1950ˆ2))` to "Age Squared."
  - Rename `bpl_1930` to "Birth State FE" and `birthyr` to "Birth Year FE."
  - Ensure the "Varying Slopes" row is clearly integrated or explained (it currently only applies to one empty-looking column).

### Figure 1: "Event Study: Sheppard-Towner Exposure and Adult Wage Income"
**Page:** 12
- **Formatting:** Professional ggplot2/Stata style. Gridlines are subtle.
- **Clarity:** The message (flat pre-trend, positive post-treatment) is clear. The shaded 95% CI is appropriate.
- **Storytelling:** Validates the parallel trends assumption perfectly.
- **Labeling:** Good. "Ref. year = 1921" is clearly noted.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Event Study: Sheppard-Towner Exposure and Educational Attainment"
**Page:** 13
- **Formatting:** Consistent with Figure 1.
- **Clarity:** Extremely clear "null" result.
- **Storytelling:** Critical for the "health vs. human capital" argument.
- **Labeling:** Excellent.
- **Recommendation:** **KEEP AS-IS** (Consider consolidating with Figure 1 as Panel B to save space, but standalone is also fine for emphasis).

### Figure 3: "Average Wage Income by Birth Cohort and Sheppard-Towner Participation"
**Page:** 14
- **Formatting:** Clean. Use of colors and shapes (dots vs. triangles) helps with accessibility.
- **Clarity:** Shows the raw data convergence well.
- **Storytelling:** Useful for showing the "age gradient" (wages falling for younger cohorts in 1950), which explains the negative signs in some raw comparisons.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**. While interesting, the Event Study (Figure 1) is the "money" figure for identification. This raw plot is more of a diagnostic.

### Figure 4: "Heterogeneous Effects of Sheppard-Towner Exposure on Wage Income"
**Page:** 15
- **Formatting:** Coefficient plot style is very "Top 5" journal ready. 
- **Clarity:** Excellent. The rural/urban and black/white contrasts are the strongest evidence for the mechanism.
- **Storytelling:** This is the "Mechanism" figure. It's the strongest part of the paper's secondary argument.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Robustness Checks and Additional Outcomes"
**Page:** 17
- **Formatting:** Column 6 header is cut off ("married_195"). Column 5 and 6 have scientific notation ($-4.89 \times 10^{-5}$) which is hard to read.
- **Clarity:** A bit cluttered. Mixing "Robustness" (Placebo, Border) with "Additional Outcomes" (Marriage, Employment) in one table makes it hard to parse.
- **Storytelling:** This table is doing too much. 
- **Labeling:** Note that standard errors for the scientific notation rows are also in scientific notation, which is messy.
- **Recommendation:** **SPLIT**
  - Create one table for **Robustness** (Columns 1-4).
  - Create a separate table or Panel for **Extensive Margin/Other Outcomes** (Employment, Marriage).
  - Convert scientific notation to decimals (e.g., -0.00005) or rescale the variable (e.g., "Employment per 1,000").

### Figure 5: "Robustness of Sheppard-Towner Effects"
**Page:** 18
- **Formatting:** Good coefficient plot.
- **Clarity:** Summarizes Table 3 visually.
- **Storytelling:** Redundant if Table 3 is clear, but good for a presentation-style paper.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Distribution of Adult Wages: Exposed Cohorts by Participation Status"
**Page:** 19
- **Formatting:** Standard density plot.
- **Clarity:** The shift is so small it is almost invisible.
- **Storytelling:** Doesn't add much beyond the mean effect already discussed.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**

### Figure 7: "Educational Attainment: Exposed Cohorts by Participation Status"
**Page:** 20
- **Formatting:** Bar chart for discrete years of schooling.
- **Clarity:** Very clear overlap.
- **Storytelling:** Again, Figure 2 (Event Study) does this more rigorously.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**

---

## Appendix Exhibits

### Table 4: "Standardized Effect Sizes: Sheppard-Towner Act Exposure"
**Page:** 30
- **Formatting:** Very detailed notes. The table structure is more of a "summary of results" than a standard appendix table.
- **Clarity:** High. The "Classification" column is helpful for a general reader.
- **Storytelling:** Excellent summary of the paper's magnitude.
- **Labeling:** Very thorough.
- **Recommendation:** **KEEP AS-IS** (Consider moving this to the main text as a "Table 4" before the conclusion to help with the "Interpretation of Magnitudes" section).

---

## Overall Assessment

- **Exhibit count:** 3 main tables, 7 main figures, 1 appendix table.
- **General quality:** The visual style is very consistent and high-quality. The paper relies heavily on figures, which is a modern trend in the AER/QJE. However, some main text figures (3, 6, 7) are more "raw data" checks that belong in an appendix.
- **Strongest exhibits:** Figure 1 (Event Study) and Figure 4 (Heterogeneity).
- **Weakest exhibits:** Table 3 (Cluttered, scientific notation) and Figure 6 (Undiscernible visual shift).
- **Missing exhibits:** 
  - **A Map:** A paper about state-level participation in the 1920s *begs* for a map of the U.S. showing which states participated and which didn't. 
  - **First Stage:** A table/figure showing the actual "dosage" (nurses per capita or clinics per state) would strengthen the "Institutional Background."

### Top 3 Improvements:
1. **Clean up Table 3:** Split into "Robustness" and "Secondary Outcomes." Eliminate scientific notation for coefficient estimates.
2. **Add a Geographic Map:** Show the 3 refuser states vs. the rest of the US. This is standard for papers exploiting state-level policy variation.
3. **Strategic Re-shuffling:** Move Figures 3, 6, and 7 to the appendix to declutter the main text. This allows the reader to focus on the high-impact causal figures (1, 2, and 4).