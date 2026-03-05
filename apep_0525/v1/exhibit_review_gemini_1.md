# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-05T16:31:00.397443
**Route:** Direct Google API + PDF
**Tokens:** 18917 in / 2106 out
**Response SHA256:** 7637000326f5d026

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Border ZIP Codes"
**Page:** 10
- **Formatting:** Clean, but missing decimal alignment. "SD share AGI..." and "Mean share AGI..." have different numbers of decimal places. The "7783" type numbers should have commas for readability.
- **Clarity:** Logical grouping. The comparison between High-Tax and Low-Tax sides is immediately clear.
- **Storytelling:** Essential. It establishes the "urbanization" confounder (higher total returns in high-tax states) early on.
- **Labeling:** Good. "agi_stub = 6" in notes is a bit technical for a general audience; "top income bracket" is better.
- **Recommendation:** **REVISE**
  - Decimal-align all share and mean columns.
  - Add thousands separators (commas) to the "ZIP-code observations" and "Mean total returns" rows.

### Figure 1: "Boundary Discontinuity in High-Income Filer Concentration"
**Page:** 13
- **Formatting:** Modern and clean. The red/blue contrast is professional. Confidence intervals are visible.
- **Clarity:** The "discontinuity" is visible, but the noise in the bins (the scatter) makes the 10-second parse difficult. The y-axis uses percentages while the text often discusses percentage points.
- **Storytelling:** This is the "hook" of the paper. It shows the raw data that motivates the study.
- **Labeling:** The x-axis "Distance to State Border (km)" is clear. The legend "High-Tax Side" and "Low-Tax Side" is helpful.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Boundary Discontinuity Estimates: Effect of High-Tax State on Income Composition"
**Page:** 14
- **Formatting:** Standard AER-style table. Horizontal rules are used correctly.
- **Clarity:** Excellent layout. Comparing Nonparametric vs. Parametric vs. Placebo in one table is very efficient.
- **Storytelling:** This is the most important table in the paper. It shows the sensitivity of the result to bandwidth and outcome variable.
- **Labeling:** Good use of significance stars. The note explaining the opposite sign conventions between estimators is crucial and well-placed.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Placebo: Low-Income Filer Concentration Shows Reverse Discontinuity"
**Page:** 15
- **Formatting:** Consistent with Figure 1.
- **Clarity:** Very clear. The "reverse" slope and jump compared to Figure 1 are immediately obvious.
- **Storytelling:** Vital for the paper’s "honest" narrative about pre-existing economic geography.
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - Consider combining Figure 1 and Figure 2 into a single Figure with Panel A (High Income) and Panel B (Low Income). This makes the "reverse discontinuity" story much more powerful.

### Figure 3: "Event Study: SALT Cap and Border Sorting"
**Page:** 16
- **Formatting:** Clean. The dashed vertical line for treatment is standard. 
- **Clarity:** The y-axis label is a bit clunky ("High-Tax Side x Year (Base: 2017)"). The massive spike in 2016 and subsequent drop to zero in 2017 (the base) is visually distracting and makes the post-2018 effect look like a recovery rather than a shift.
- **Storytelling:** It shows the *lack* of a sharp break, which is a key part of the author's nuanced conclusion.
- **Labeling:** The "SALT Cap (Jan 2018)" annotation is helpful.
- **Recommendation:** **REVISE**
  - The y-axis units (0.00 to 0.05) should be explained: are these percentage points or shares?
  - Add a note explaining the 2016 volatility (is this driven by a specific state's tax change?).

### Table 3: "Triple-Difference Estimates: Income × Border Side × Post-SALT"
**Page:** 17
- **Formatting:** Basic.
- **Clarity:** A bit cluttered. The interaction terms are long and repetitive.
- **Storytelling:** This is the "clean" tax effect estimate. It deserves more prominence.
- **Labeling:** "Term" column is clear, but "Estimate" needs to specify it's a coefficient.
- **Recommendation:** **REVISE**
  - Use standard notation for interactions (e.g., $HighSide \times HighInc \times Post$).
  - Group into Panel A (Main Effects) and Panel B (Interactions) if possible, or move main effects to a note and focus the table on the triple interaction.

### Table 4: "RDD Estimates by Border Pair"
**Page:** 17
- **Formatting:** Standard. 
- **Clarity:** Clear, but the NJ-PA estimate (0.3587) is so much larger than the others it looks like a typo to the uninitiated.
- **Storytelling:** Highlights the heterogeneity and the dominance of the NJ-PA corridor.
- **Labeling:** "Effective N" is a good inclusion for RDD.
- **Recommendation:** **REVISE**
  - Add a column for "State Names" (e.g., New Jersey/Pennsylvania) rather than just codes to help readers not familiar with US abbreviations.

### Table 5: "Period-Specific RDD Estimates: Pre-SALT, Post-SALT, and COVID"
**Page:** 18
- **Formatting:** Consistent with Table 4.
- **Clarity:** Very easy to read.
- **Storytelling:** Reinforces the gradual nature of the change.
- **Labeling:** Good.
- **Recommendation:** **MOVE TO APPENDIX**
  - This is a less-powered version of the Event Study (Figure 3). It supports the story but doesn't need to be in the main text.

### Figure 4: "Bandwidth Sensitivity"
**Page:** 19
- **Formatting:** Clean.
- **Clarity:** High. Shows the sign reversal perfectly.
- **Storytelling:** Essential for the paper's critique of "naive" RDD in this setting.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS** (Or merge into a "Robustness" Figure in Appendix).

### Table 6: "Validity Tests: Density and Covariate Balance at the Border"
**Page:** 20
- **Formatting:** Clean.
- **Clarity:** The mixture of a t-statistic (McCrary) and coefficients (total_returns) in the "Estimate" column is slightly confusing.
- **Storytelling:** Essential "housekeeping" for an RDD paper.
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - Add a column for "Metric Type" (e.g., "t-stat" vs "Coefficient") or use footnotes to distinguish.

---

## Appendix Exhibits

### Figure 5: "Bandwidth Sensitivity (Appendix)"
**Page:** 31
- **Recommendation:** **REMOVE**
  - This is an exact duplicate of Figure 4 from the main text.

### Table 7: "Robustness: Alternative Specifications"
**Page:** 32
- **Recommendation:** **KEEP AS-IS**
  - Good summary of donut and polynomial checks.

### Figure 6: "Period-Specific RDD Estimates"
**Page:** 33
- **Recommendation:** **KEEP AS-IS**
  - A good visual companion to Table 5.

### Figure 7: "Border-Pair Heterogeneity in Tax Sorting"
**Page:** 34
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - This forest plot is much more visually compelling than Table 4 and immediately shows how much NJ-PA is an outlier. Top journals love forest plots for heterogeneity.

---

## Overall Assessment

- **Exhibit count:** 6 main tables, 4 main figures, 1 appendix table, 3 appendix figures
- **General quality:** High. The visuals are produced using modern packages (looks like R/ggplot2) and follow standard academic conventions.
- **Strongest exhibits:** Figure 1 (Main RDD), Table 2 (Core results/Placebo), Figure 7 (Forest plot).
- **Weakest exhibits:** Table 5 (Redundant), Figure 5 (Duplicate).
- **Missing exhibits:** 
    - **A Map:** For a geographic paper, a map showing the 8 border segments and the ZIP code centroids would be highly effective for an AER/QJE audience.
    - **Raw Discontinuity Plot for NJ-PA:** Since this border drives so much of the result, a specific figure for this pair would be helpful.

**Top 3 improvements:**
1. **Consolidate Figures 1 and 2:** Putting the main result and the placebo side-by-side (Panel A/B) makes the argument about "economic geography vs. taxes" visually undeniable.
2. **Promote Figure 7 (Forest Plot):** Replace Table 4 with this figure in the main text. It communicates the heterogeneity much faster.
3. **Map of Study Area:** Add a Figure 0 or Figure 1 that shows the US with the treated borders highlighted. This grounds the "Distance to Border" metric in real geography.