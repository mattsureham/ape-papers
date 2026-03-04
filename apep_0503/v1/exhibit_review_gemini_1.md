# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-04T12:52:36.806611
**Route:** Direct Google API + PDF
**Tokens:** 20997 in / 1852 out
**Response SHA256:** 94b444412941df34

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics by DPE Label"
**Page:** 11
- **Formatting:** Standard academic layout. Good use of horizontal lines (top, below headers, bottom). Numbers are mostly right-aligned but should be strictly decimal-aligned.
- **Clarity:** Clean. The comparison across labels is intuitive.
- **Storytelling:** Essential. It immediately justifies the RDD by showing that raw prices are non-monotonic, necessitating the local identification strategy.
- **Labeling:** Good notes. Suggest adding "(Standard Deviation)" to the "SD Price" column header for absolute clarity.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "RDD Estimates at DPE Band Boundaries"
**Page:** 15
- **Formatting:** Excellent. Grouping columns into "Regulatory" and "Information-Only" is very professional and mimics top-tier journal styles (AER/QJE).
- **Clarity:** The main result (Column 1) stands out immediately.
- **Storytelling:** This is the heart of the paper. It shows the "teeth" vs. "labels" argument perfectly.
- **Labeling:** Significance stars and standard error notes are correct. "Eff. N" and "Bandwidth" are standard.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "McCrary Density Tests for Manipulation"
**Page:** 17
- **Formatting:** Clean and consistent with other tables.
- **Clarity:** High. Clearly shows the failure to reject manipulation at the primary G/F boundary.
- **Storytelling:** Vital for internal validity. It addresses the "sorting" concern head-on.
- **Labeling:** Descriptive notes. Units included in the header.
- **Recommendation:** **KEEP AS-IS** (Though Figure 4 is the visual equivalent, keeping this in the main text is standard for RDD papers).

### Table 4: "Robustness: Donut RDD and Bandwidth Sensitivity at G/F Cutoff"
**Page:** 18
- **Formatting:** Good use of Panel A and Panel B.
- **Clarity:** Panel B is clear; Panel A is a bit startling because the coefficients flip sign and lose significance with wider donuts (as expected/explained in text).
- **Storytelling:** Strengthens the main result by showing it isn't driven by observations right at the edge.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Pre-Ban vs. Post-Ban RDD Estimates at G/F Cutoff"
**Page:** 20
- **Formatting:** Consistent.
- **Clarity:** The N=93 for Post-Ban makes this column effectively uninterpretable.
- **Storytelling:** While the pre-ban result is interesting for "anticipation," the Post-Ban column is very weak due to sample size. 
- **Recommendation:** **MOVE TO APPENDIX** (The small N makes it look like a "failed" result that clutters the main text's strong narrative).

---

## Appendix Exhibits

### Table 6: "McCrary Density Tests: Full Results"
**Page:** 30
- **Formatting:** Identical to Table 3.
- **Clarity:** Good.
- **Storytelling:** Redundant. Table 3 already shows all 6 cutoffs.
- **Recommendation:** **REMOVE** (Table 3 in the main text is already the "Full Results").

### Table 7: "Covariate Balance at DPE Cutoffs"
**Page:** 31
- **Formatting:** Good. Logical layout by cutoff and covariate.
- **Clarity:** High.
- **Storytelling:** Essential for the RDD's "as-good-as-random" claim.
- **Recommendation:** **PROMOTE TO MAIN TEXT** (This is a core validity requirement for top journals).

### Table 8: "Placebo Cutoff Tests"
**Page:** 31
- **Formatting:** Standard.
- **Clarity:** Clear.
- **Storytelling:** Supports the idea that discontinuities only happen at label boundaries.
- **Recommendation:** **KEEP AS-IS** (Appendix)

### Figure 1: "Bandwidth Sensitivity at the G/F Cutoff"
**Page:** 32
- **Formatting:** Professional ggplot2 style. Red points and error bars are clear.
- **Clarity:** High. Shows stability across multipliers.
- **Storytelling:** Visual version of Table 4 Panel B.
- **Recommendation:** **KEEP AS-IS** (Appendix)

### Figure 2: "Distribution of DPE Energy Scores and Regulatory Timeline"
**Page:** 34
- **Formatting:** Colors correspond to actual French DPE labels (Green to Red). Very helpful.
- **Clarity:** Panel A is a bit busy with many dashed lines, but readable. Panel B is a great "cheat sheet" for the reader.
- **Storytelling:** This is the "Introduction Figure" that explains the whole identification strategy.
- **Recommendation:** **PROMOTE TO MAIN TEXT** (Move to Section 2. Place it as Figure 1 in the whole paper).

### Figure 3: "RDD Estimates at DPE Band Boundaries"
**Page:** 35
- **Formatting:** Excellent multi-panel bin-scatter plots.
- **Clarity:** Shows the "jump" at G/F and the "smoothness" elsewhere.
- **Storytelling:** This is the most "convincing" visual in the paper. 
- **Recommendation:** **PROMOTE TO MAIN TEXT** (This should be the headline Figure 2 in the results section).

### Figure 4: "McCrary Density Tests at DPE Cutoffs"
**Page:** 36
- **Formatting:** Standard histograms with density overlays.
- **Clarity:** Very high.
- **Storytelling:** Visual proof of no sorting at G/F.
- **Recommendation:** **KEEP AS-IS** (Appendix, as Table 3 is already in the main text).

### Figure 5: "Multi-Cutoff Coefficient Plot"
**Page:** 37
- **Formatting:** Excellent summary plot.
- **Clarity:** The color-coding (Green/Red) for Info vs. Regulatory is perfect.
- **Storytelling:** Summarizes the entire paper in one image.
- **Recommendation:** **PROMOTE TO MAIN TEXT** (This is the "10-second parse" figure for the Conclusion or Results summary).

### Figure 6: "Pre-Ban vs. Post-Ban Price Discontinuity at G/F Boundary"
**Page:** 38
- **Formatting:** Professional.
- **Clarity:** The Post-Ban line is very noisy due to low N.
- **Storytelling:** Interesting, but the "Post-Ban" data is too thin to be a main result.
- **Recommendation:** **KEEP AS-IS** (Appendix)

---

## Overall Assessment

- **Exhibit count:** 5 main tables, 0 main figures, 3 appendix tables, 6 appendix figures.
- **General quality:** The tables are extremely polished and journal-ready. The figures are currently "hidden" in the appendix but are actually the strongest part of the paper's visual storytelling.
- **Strongest exhibits:** Table 2 (Results), Figure 3 (Bin-scatters), Figure 5 (Coefficient plot).
- **Weakest exhibits:** Table 5 (Low N in post-ban), Table 6 (Redundant).
- **Missing exhibits:** A map showing the geographic distribution of "Energy Sieves" (G-rated properties) across France would be a standard "Figure 1" for a spatial/housing paper in an AEJ or AER.

**Top 3 improvements:**
1. **Promote the Figures:** Move Figure 2 (Institutional Background), Figure 3 (RDD Bin-scatters), and Figure 5 (Coefficient Plot) to the main text. Currently, the main text is "all text and tables," which makes it dense and less engaging.
2. **Promote Covariate Balance:** Move Table 7 to the main text. Top journals prioritize internal validity; hiding the balance tests in the appendix can signal lack of confidence to a reviewer.
3. **Add a Map:** Include a choropleth map of France showing the percentage of G-rated properties by department or commune to show the "where" of the policy's impact.