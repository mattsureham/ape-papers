# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-12T13:56:04.689683
**Route:** Direct Google API + PDF
**Tokens:** 19957 in / 1931 out
**Response SHA256:** 638fc1a1a980ea06

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Pre-Treatment Means (2010–2014)"
**Page:** 11
- **Formatting:** Clean and professional. Good use of horizontal rules (booktabs style).
- **Clarity:** Excellent. The comparison between Progressive DA, All Controls, and Metro Controls clearly justifies the empirical strategy.
- **Storytelling:** Essential. It establishes the "selection into treatment" problem (treated counties are much larger and have lower baseline jail rates).
- **Labeling:** Clear. Standard errors/SDs are in parentheses. Units like "Population (K)" are helpful.
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Panel A: Effect on County Jail Population Rate (per 100,000)"
**Page:** 14
- **Formatting:** Standard journal format. Numbers are well-aligned.
- **Clarity:** High. The progression from baseline to metro-only and entropy balancing is logical.
- **Storytelling:** This is the "money table" for the first half of the paper. It shows the result is robust but the magnitude is sensitive to the control group.
- **Labeling:** Notes are comprehensive. Significance stars are standard.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Event Study: Effect of Progressive DA on Jail Population Rate"
**Page:** 15
- **Formatting:** High quality. Clean background, legible font sizes.
- **Clarity:** The message—flat pre-trends and a sharp post-treatment break—is visible in seconds.
- **Storytelling:** Crucial for validating the Parallel Trends Assumption.
- **Labeling:** Axis labels are descriptive. Reference period ($t=-1$) is noted.
- **Recommendation:** **REVISE**
  - Change the y-axis title to "Estimated ATT" to match the legend and text.
  - Add a vertical dashed line at $t=-0.5$ (between -1 and 0) to clearly demarcate the treatment start.

### Figure 2: "Event Study Comparison: Full Sample vs. Metro-Only Control Group"
**Page:** 16
- **Formatting:** Consistent with Figure 1. 
- **Clarity:** Slightly cluttered due to overlapping confidence intervals. The two shades of grey are hard to distinguish.
- **Storytelling:** Important for showing that while point estimates change with the control group, the dynamic pattern is identical.
- **Labeling:** Good.
- **Recommendation:** **REVISE**
  - Use different line styles (solid vs. dashed) or high-contrast colors (e.g., navy and maroon) instead of two shades of grey to distinguish the two series.

### Table 3: "Panel B: Effect on Homicide Mortality Rate (per 100,000)"
**Page:** 17
- **Formatting:** Consistent with Table 2.
- **Clarity:** Very simple, perhaps too simple (only 2 columns).
- **Storytelling:** Necessary to address the "public safety" counter-argument.
- **Labeling:** Good.
- **Recommendation:** **REVISE**
  - Consider merging Table 2 and Table 3 into a single Table 2 with Panel A (Jail) and Panel B (Homicide). This is common in top journals to save space and group "Primary Outcomes."

### Figure 3: "Event Study: Effect of Progressive DA on Homicide Rate"
**Page:** 17
- **Formatting:** Consistent.
- **Clarity:** Clear, but highlights the data limitation (very short pre-period).
- **Storytelling:** High integrity—it shows why the author is cautious about the homicide results.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Racial Decomposition: Differential Effects on Black vs. White Jail Rates"
**Page:** 18
- **Formatting:** Professional.
- **Clarity:** Mixed. Column 2 (Ratio) has a different scale/interpretation than Columns 1 and 3 (per 10K).
- **Storytelling:** This is the core of the "Paradox" argument. 
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - The units in (1) and (3) are "per 10K" while Table 2 was "per 100K". For consistency across the paper, convert Table 4 to "per 100,000" to match Table 2.

### Figure 4: "Race-Specific Event Studies: The Equity Paradox"
**Page:** 19
- **Formatting:** Professional.
- **Clarity:** High impact. The divergence between the two lines is the visual "hook" of the paper.
- **Storytelling:** The most important figure in the paper.
- **Labeling:** Needs a legend.
- **Recommendation:** **REVISE**
  - Add a legend inside the plot area identifying which line is Black and which is White. Currently, the reader has to guess or find it in the text.

### Table 5: "Robustness: Effect on Jail Population Rate"
**Page:** 21
- **Formatting:** Standard. 7 columns is the upper limit for a portrait page, but it fits.
- **Clarity:** Clear.
- **Storytelling:** Standard "kitchen sink" robustness. 
- **Labeling:** Good.
- **Recommendation:** **MOVE TO APPENDIX**
  - This is a standard robustness table. The main text results (Table 2) are already quite robust. Moving this to the Appendix would tighten the narrative.

---

## Appendix Exhibits

### Figure 5: "Progressive DA Treatment Timeline"
**Page:** 29
- **Formatting:** Clean.
- **Recommendation:** **KEEP AS-IS** (Excellent for showing staggered timing).

### Figure 6: "Geographic Distribution of Progressive DA Counties"
**Page:** 30
- **Formatting:** High quality.
- **Recommendation:** **KEEP AS-IS**

### Table 7: "Progressive District Attorney Counties: Treatment Details"
**Page:** 31
- **Formatting:** Good.
- **Recommendation:** **KEEP AS-IS** (Essential for transparency).

### Table 8: "Callaway-Sant’Anna (2021) Simple ATT Estimates"
**Page:** 32
- **Recommendation:** **REMOVE**
  - This is redundant. These coefficients are already discussed in the main text and shown in the event studies.

### Figure 7: "Raw Trends in Jail Rates: Progressive DA vs. Other Counties"
**Page:** 32
- **Formatting:** Professional.
- **Storytelling:** This is a "pre-estimation" check. 
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - Top journals (AER/QJE) almost always require a "raw data" figure before the DiD results to show that the trends were similar before any model was applied.

### Figure 8: "Randomization Inference: Distribution of Permuted Coefficients"
**Page:** 33
- **Recommendation:** **KEEP AS-IS**

### Figure 9: "Leave-One-Out Influence Analysis"
**Page:** 34
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 4 main tables, 4 main figures, 2 appendix tables, 5 appendix figures.
- **General quality:** Extremely high. The formatting is nearly AER/QJE ready. The use of modern DiD methods (CS-DiD) is visually well-supported.
- **Strongest exhibits:** Figure 4 (Paradox visualization) and Table 1 (Balance table).
- **Weakest exhibits:** Figure 2 (overlapping grey shades) and Figure 4 (missing legend).
- **Missing exhibits:** A **Binscatter** or **Scatter plot** of the relationship between "Baseline Black Share" and "Change in Jail Rate" could help visualize the mechanism of the "Universalism Paradox."

**Top 3 Improvements:**
1. **Visual Distinction:** Use distinct colors/styles in Figure 2 and add a legend to Figure 4. The "Paradox" is the paper's contribution; it must be visually unmistakable.
2. **Consolidate Results:** Merge Table 2 (Jail) and Table 3 (Homicide). This creates a single "Main Results" table that shows the reader the trade-off (or lack thereof) in one glance.
3. **Bring Raw Data Forward:** Promote Figure 7 (Raw Trends) to the main text (Section 3 or 5). Showing raw means before coefficients is a "gold standard" for transparency in DiD papers.