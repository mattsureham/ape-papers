# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-28T01:34:01.325439
**Route:** Direct Google API + PDF
**Tokens:** 17877 in / 2144 out
**Response SHA256:** 4c05180d7e87137f

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics"
**Page:** 7
- **Formatting:** Clean and professional. Follows standard top-journal convention (no vertical lines, panel structure).
- **Clarity:** Excellent. Splitting by "Releases by Medium" and "Sample Characteristics" provides a quick snapshot of both the data distribution and the panel dimensions.
- **Storytelling:** Strong. It immediately highlights the "zero-inflation" problem mentioned in the text (e.g., Land at 95.8% zero) which justifies the later functional form choices.
- **Labeling:** Clear. Units (pounds) and time periods are well-defined.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Overlap Between CAA and CWA Enforcement"
**Page:** 8
- **Formatting:** Modern and clean. The gridlines are subtle. 
- **Clarity:** The stacked bar chart effectively shows the relative frequency of overlap. However, the color "Both CAA + CWA" (pink) is a very thin sliver at the bottom; it is hard to see its trend over time.
- **Storytelling:** Crucial. This motivates the entire paper by showing that many facilities are hit by both regulatory regimes simultaneously.
- **Labeling:** Good. 
- **Recommendation:** **REVISE**
  - Increase the visual prominence of the "Both" category. Perhaps use a line overlay for the count of overlapping inspections or a secondary y-axis to show the *percentage* of overlap, which is the institutional channel of interest.

### Table 2: "Cross-Media Pollution Substitution: Main Results"
**Page:** 11
- **Formatting:** Professional. Decimal points are aligned. 
- **Clarity:** Very clean. Column (1) vs (2) makes the stability of the $\tau$ coefficient obvious.
- **Storytelling:** This is the "hook" of the paper. It shows the strong relative effect that the rest of the paper will eventually deconstruct.
- **Labeling:** Significance stars and clustering are properly noted. The note explains the reparameterization formula clearly.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Heterogeneity-Robust Estimation: TWFE vs. Stacked DiD"
**Page:** 11
- **Formatting:** Standard. 
- **Clarity:** Logical comparison.
- **Storytelling:** Potentially redundant. This is a robustness check (addressing staggered adoption concerns) that might be better suited as columns (3) and (4) in Table 2 or moved to the appendix.
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - **Consolidate:** Merge this into Table 2. Having them separate feels like "fishing" for more main-text exhibits. A single "Main Estimates" table with 3–4 columns (Baseline, CWA Controls, Stacked) is much more standard for an AER-style paper.

### Figure 2: "Event Study: Air vs. Non-Air Releases Around CAA Inspection"
**Page:** 12
- **Formatting:** Professional. Use of shaded 95% CIs is standard.
- **Clarity:** The divergence at $t=0$ is very easy to parse in under 10 seconds.
- **Storytelling:** This is the most important figure in the paper. It shows the "Parallel Trends" for the differential and the persistence of the effect.
- **Labeling:** Axes are well-labeled.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Medium-Specific Decomposition: Effect of CAA Inspections by Release Pathway"
**Page:** 13
- **Formatting:** A bit sparse. Only 3 columns for 4 rows.
- **Clarity:** High. 
- **Storytelling:** This is the "Aha!" moment where the illusion is revealed (Air is +; Water is -). 
- **Labeling:** Note is comprehensive.
- **Recommendation:** **REVISE**
  - Add a "Pre-inspection Mean" column. This allows the reader to judge the economic magnitude of the coefficients (e.g., is -0.0287 large relative to the mean?).

### Figure 3: "Medium-Specific Event Studies"
**Page:** 14
- **Formatting:** 2x2 grid is standard and clean.
- **Clarity:** Good, but the y-axis scales differ across panels (-0.1 to 0.0 for Air; -0.06 to 0.06 for Water). This is technically correct but can be visually misleading.
- **Storytelling:** Directly supports Table 4.
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - Try to use a common y-axis scale across all four panels if possible, or at least for Air and Water, to allow the reader to visually compare the "composition" shift's magnitude across media.

### Table 5: "Mechanism Test: CAA-Regulated vs. Non-CAA Chemicals"
**Page:** 15
- **Formatting:** Standard.
- **Clarity:** Clear split-sample design.
- **Storytelling:** Important for ruling out simple "strategic substitution."
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Mechanism: CAA vs. Non-CAA Chemical Event Studies"
**Page:** 16
- **Formatting:** This is a "coefficient plot" rather than an event study.
- **Clarity:** Very high.
- **Storytelling:** Summarizes the results of Table 5 visually.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 6: "Magnitudes and Environmental Relevance"
**Page:** 16
- **Formatting:** Good use of horizontal lines to separate sections.
- **Clarity:** A bit "busy" for a table—it’s essentially a summary of other results plus a calculation.
- **Storytelling:** Helps with the "So what?" question.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Magnitudes: Relative Differential vs. Medium-Specific Effects"
**Page:** 17
- **Formatting:** High quality.
- **Clarity:** Excellent. This is a very creative way to visualize the "Illusion" by comparing the pooled coefficient to the medium-specific ones.
- **Storytelling:** Potentially the "image of the paper."
- **Labeling:** Legend is clear.
- **Recommendation:** **KEEP AS-IS**

### Table 7: "Heterogeneity Analysis"
**Page:** 18
- **Formatting:** Standard.
- **Clarity:** High.
- **Storytelling:** Supports the idea that the illusion is driven by enforcement intensity.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 8: "Robustness Checks"
**Page:** 18
- **Formatting:** Dense but readable.
- **Clarity:** Standard "column-per-check" format.
- **Storytelling:** Necessary for a top journal to show the result isn't a fluke of clustering or window choice.
- **Labeling:** Very good notes on RI p-values and Wald tests.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Table 9: "Composition Outcomes: Air Share, Total Releases, and Air-Only Releases"
**Page:** 30
- **Formatting:** Standard.
- **Storytelling:** This provides the "balance" to the main argument. If Air Share doesn't move, the relative differential *must* be an artifact. 
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - This is a core part of the "Composition Illusion" proof. It should likely be in the main text, perhaps combined with Table 4.

### Table 10: "Functional Form Robustness"
**Page:** 31
- **Recommendation:** **KEEP AS-IS** (Appropriate for Appendix)

### Table 11: "Extensive Margin: Probability of Any Release by Medium"
**Page:** 31
- **Recommendation:** **KEEP AS-IS** (Appropriate for Appendix)

---

## Overall Assessment

- **Exhibit count:** 8 main tables, 5 main figures, 3 appendix tables, 0 appendix figures.
- **General quality:** Extremely high. The paper follows the "Visual Essay" style where figures (especially Fig 5) do a lot of the heavy lifting.
- **Strongest exhibits:** Figure 5 (Visualizes the 'Illusion'), Figure 2 (Classic Event Study), Table 1.
- **Weakest exhibits:** Table 3 (Redundant), Table 4 (Missing mean comparison).
- **Missing exhibits:** A **Map** showing the geographic distribution of TRI facilities and CAA/CWA overlap would be standard for a QJE/AER-style paper to show the "where" of the data.

### Top 3 Improvements:
1.  **Consolidate Table 2 and Table 3:** Combine the TWFE and Stacked results into one "Main Results" table. This creates a more "bulletproof" first result.
2.  **Enhance Figure 1:** Make the "Overlap" (Both) category more visible. This is the institutional mechanism, so it should be the most striking part of the chart.
3.  **Promote Table 9:** The "Composition Outcomes" are central to the paper's theoretical contribution. Moving these to the main text (or merging them with the Table 4 decomposition) reinforces the "Illusion" argument more forcefully than just showing the decomposition.