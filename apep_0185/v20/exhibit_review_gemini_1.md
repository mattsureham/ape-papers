# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-05T00:19:17.768735
**Route:** Direct Google API + PDF
**Tokens:** 28797 in / 2375 out
**Response SHA256:** fff51979e1024e3b

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Figure 1: "Population-Weighted Network Minimum Wage Exposure by County"
**Page:** 12
- **Formatting:** Excellent. Professional color gradient (Viridis-style) is accessible. The legend is clear and placed well.
- **Clarity:** High. The contrast between the coastal ties and the interior is immediately apparent.
- **Storytelling:** Essential. It establishes the "treatment" variation and justifies the paper's focus on within-state variation.
- **Labeling:** Clear. Units ($) are included.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Population-Weighted Minus Probability-Weighted Exposure Gap"
**Page:** 13
- **Formatting:** Clean. Diverging color scale (Red-Blue) is appropriate for a "gap" measure.
- **Clarity:** Good. It clearly identifies where the paper's methodological contribution (population weighting) matters most.
- **Storytelling:** Strong. It supports the theoretical argument that scale differs from probability.
- **Labeling:** Axis and legend are clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Within-State Residual Variation in the Instrumental Variable"
**Page:** 14
- **Formatting:** Multi-panel (Panel A and B) is well-handled. Consistent scale across panels.
- **Clarity:** Crucial for identification. Shows that even after state fixed effects, variation remains.
- **Storytelling:** Directly addresses the "identification" concern by showing the variation being exploited.
- **Labeling:** Legend "Residual IV" is technically accurate but perhaps could be labeled "Residualized Exposure" for the lay reader.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "First Stage: Out-of-State vs. Full Network Exposure"
**Page:** 18
- **Formatting:** Professional binned scatter. Inclusion of slope and F-stat inside the plot is standard for top journals.
- **Clarity:** Very high. 10-second parse: "The instrument is very strong."
- **Storytelling:** Standard requirement for IV papers.
- **Labeling:** Axis labels include units (log MW).
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Distance-Credibility Tradeoff"
**Page:** 21
- **Formatting:** Dual-axis plot. Generally discouraged in some journals but here it works to show the intersection of two metrics.
- **Clarity:** Good. The "sweet spot" (100–250km) is easy to see.
- **Storytelling:** High value. It explains why the authors choose specific distance thresholds.
- **Labeling:** "F = 10" and "p = 0.05" lines are helpful annotations.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Pre-Treatment Employment Trends by IV Quartile"
**Page:** 22
- **Formatting:** Standard "parallel trends" style plot. 
- **Clarity:** A bit cluttered with the seasonality.
- **Storytelling:** Vital for DiD/Shift-share validity.
- **Labeling:** Legend is clear. 
- **Recommendation:** **REVISE**
  - Change the y-axis to "Residual Log Employment" (residualized by county FE) so that the lines overlap at a base period (e.g., 2012). This would make the "parallel" nature much easier to see than the current level-shifted lines.

### Figure 7: "Net Migration by Network Exposure Quartile, 2012–2019"
**Page:** 26
- **Formatting:** Consistent with Figure 6.
- **Clarity:** High. Shows the null result for the migration channel.
- **Storytelling:** Important for ruling out the "Migration" mechanism.
- **Labeling:** Units are "Returns" (IRS data), which is clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 8: "Heterogeneity by Census Division"
**Page:** 29
- **Formatting:** Horizontal coefficient plot. Excellent use of whitespace.
- **Clarity:** Extremely clear. The "Overall OLS" red line is a great benchmark.
- **Storytelling:** Supports the "information" channel by showing higher effects where the wage gap is largest.
- **Labeling:** Labels are descriptive (West South Central, etc.).
- **Recommendation:** **KEEP AS-IS**

### Table 1: "Network Minimum Wage Exposure and Local Labor Market Outcomes"
**Page:** 39
- **Formatting:** Journal-ready. Professional borders, Panel A/B structure, decimal-aligned.
- **Clarity:** Excellent logical flow (OLS $\to$ IV $\to$ Distant IV $\to$ Specification Test).
- **Storytelling:** The "hero" table of the paper.
- **Labeling:** Significance stars and SE parentheses are properly noted.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "USD-Denominated Specifications: 2SLS Estimates"
**Page:** 40
- **Formatting:** Clean.
- **Clarity:** High. Translates abstract logs into "cents/dollars."
- **Storytelling:** Provides the "headline" numbers used in the abstract and intro.
- **Labeling:** "Network Avg MW (USD)" is a very clear row title.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Shock Contribution Diagnostics"
**Page:** 40
- **Formatting:** Good.
- **Clarity:** High. Shows that no single state (like CA) is driving the whole result.
- **Storytelling:** Critical for shift-share (Borusyak et al. 2022) requirements.
- **Labeling:** HHI note at the bottom is helpful.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Balance Tests: Pre-Period Characteristics by IV Quartile"
**Page:** 41
- **Formatting:** Standard balance table.
- **Clarity:** Good.
- **Storytelling:** Honest reporting of the lack of balance in levels, justifying the use of Fixed Effects.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Shock-Robust Inference"
**Page:** 41
- **Formatting:** Clean.
- **Clarity:** Good.
- **Storytelling:** Technical robustness.
- **Recommendation:** **MOVE TO APPENDIX** — This is a standard check that doesn't change the story; Table 1 already establishes significance. Main text flow would improve.

### Table 6: "Job Flow Mechanism: Effects of Network Exposure on Labor Market Dynamics"
**Page:** 42
- **Formatting:** Panel-like row structure.
- **Clarity:** Good.
- **Storytelling:** Essential for the "Churn/Information" mechanism story.
- **Recommendation:** **KEEP AS-IS**

### Table 7: "Migration Mechanism Tests: IRS County-to-County Flows"
**Page:** 42
- **Formatting:** Clean.
- **Clarity:** Good.
- **Storytelling:** Rules out migration.
- **Recommendation:** **KEEP AS-IS** (Could potentially be merged into a "Mechanism Summary" table with Table 6, but separate is fine).

### Table 8: "Policy Diffusion: Network Exposure and Future Minimum Wage Changes"
**Page:** 43
- **Formatting:** Professional.
- **Clarity:** Clear "Null" results.
- **Storytelling:** Rules out the "Political/Endogeneity" channel.
- **Recommendation:** **MOVE TO APPENDIX** — While important, the labor market results are the focus. This is a secondary falsification.

---

## Appendix Exhibits

### Table 9: "Distance-Credibility Analysis: Instrument Strength, Balance, and Treatment Effects"
**Page:** 46
- **Recommendation:** **KEEP AS-IS** — This is the data source for Figure 5.

### Table 10: "LATE Complier Characterization: County Characteristics by IV Sensitivity Quartile"
**Page:** 46
- **Recommendation:** **KEEP AS-IS**

### Table 11: "Robustness: Sample Restrictions (2SLS)"
**Page:** 47
- **Recommendation:** **KEEP AS-IS**

### Table 12: "Robustness: Leave-One-State-Out (2SLS)"
**Page:** 48
- **Recommendation:** **KEEP AS-IS**

### Table 13: "Placebo Instrument Tests"
**Page:** 49
- **Recommendation:** **KEEP AS-IS**

### Table 14: "Robustness: Alternative Controls (2SLS)"
**Page:** 50
- **Recommendation:** **KEEP AS-IS**

### Table 15: "Falsification: Placebo Network Exposures and MW Adoption"
**Page:** 51
- **Recommendation:** **KEEP AS-IS**

### Figure 9: "Policy Diffusion: Distance Monotonicity"
**Page:** 52
- **Recommendation:** **KEEP AS-IS**

### Figure 10: "Probability-Weighted Network Minimum Wage Exposure by County"
**Page:** 53
- **Recommendation:** **KEEP AS-IS** — Essential companion to Figure 1.

---

## Overall Assessment

- **Exhibit count:** 8 main tables (post-recommendations: 6), 8 main figures, 7 appendix tables, 2 appendix figures.
- **General quality:** Extremely high. The paper follows the modern "Visual First" standard of top-tier journals. Figures are aesthetically consistent and logically sequenced.
- **Strongest exhibits:** Table 1 (Comprehensive), Figure 8 (Geographic Heterogeneity), Figure 1 (Exposure Map).
- **Weakest exhibits:** Figure 6 (Seasonality makes trends hard to compare), Table 5 (Too technical for main text).
- **Missing exhibits:** A **Summary Statistics** table is missing. Even though Table 4 provides some, a standard Table 1 showing Mean/SD/Min/Max for all variables (Earnings, Emp, Exposure, Hires, etc.) is a baseline expectation for AER/QJE.
- **Top 3 improvements:**
  1. **Add a Summary Statistics Table** as the new Table 1.
  2. **De-mean/Residualize Figure 6:** Plot the quartiles relative to a base year and remove seasonal fluctuations (or use yearly averages) to make "parallel trends" visually undeniable.
  3. **Streamline the Main Text:** Move Table 5 (Inference) and Table 8 (Policy Diffusion) to the Appendix to keep the reader focused on the primary labor market findings.