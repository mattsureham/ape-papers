# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-09T11:55:06.602505
**Route:** Direct Google API + PDF
**Tokens:** 21517 in / 2237 out
**Response SHA256:** 9f7b42f76ef713ee

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Pre-Treatment Descriptive Statistics by Treatment Group (2010–2015)"
**Page:** 11
- **Formatting:** Clean and professional. Uses standard booktabs-style horizontal lines. Numbers are appropriately rounded.
- **Clarity:** Excellent. The grouping of "Treated x Pastoral" vs. "Control x Pastoral" allows the reader to quickly verify baseline balance in the 10-second window.
- **Storytelling:** Strong. It justifies the triple-difference by showing that "Non-Pastoral" areas have almost zero violence, making them a perfect within-state control.
- **Labeling:** Clear. Column headers include units (N, Mean, SD).
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Effect of Anti-Open Grazing Laws on Violence: Triple-Difference Estimates"
**Page:** 14
- **Formatting:** High journal quality. Standard errors are correctly placed in parentheses below coefficients. Asterisks are used appropriately.
- **Clarity:** Logical progression from simple DiD (Col 1) to the preferred DDD with State-Year fixed effects (Col 3).
- **Storytelling:** This is the "money table." It clearly shows the sign reversal when adding state-year FEs, highlighting the importance of the DDD design.
- **Labeling:** Good. Note defines the outcome variables and the "Pastoral" indicator. 
- **Recommendation:** **REVISE**
  - **Specific Change:** Decimal-align the coefficients and standard errors. Currently, the negative signs and varying digit counts cause the numbers to "drift" horizontally, which is frowned upon in top-5 journals.

### Figure 1: "Dynamic Treatment Effects: Non-State Violence (Callaway-Sant’Anna)"
**Page:** 15
- **Formatting:** Clean "white" theme. Consistent with modern AEJ/AER styles.
- **Clarity:** The vertical dashed line at $t=-1$ is standard. However, the y-axis (ATT) has a large range ($ -5$ to $15$) that makes the post-treatment decline look smaller than it is.
- **Storytelling:** Vital for showing the absence of pre-trends. It shows a spike at $t=0$, which the text explains as implementation-period upheaval.
- **Labeling:** Axis labels are present. The title is descriptive.
- **Recommendation:** **REVISE**
  - **Specific Change:** Change the point markers for the pre-treatment period (e.g., open circles) versus post-treatment (solid circles) to visually separate the "test of assumptions" from the "results."

### Figure 2: "Placebo Event Study: State-Based Violence (Should Be Null)"
**Page:** 16
- **Formatting:** Identical to Figure 1, providing good consistency.
- **Clarity:** The red color for the point markers is a nice touch to distinguish the placebo from the main result.
- **Storytelling:** Effectively proves the specificity of the law's impact.
- **Labeling:** "Should be null" in the subtitle is helpful but perhaps too "on the nose" for a formal journal; usually, this is left for the text or notes.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Non-State Violence Trends by Anti-Grazing Law Adoption Group"
**Page:** 17
- **Formatting:** Shaded 95% CIs are a bit dense and overlap significantly, creating a "muddy" look in the 2010–2016 period.
- **Clarity:** Hard to distinguish the three lines in the early years.
- **Storytelling:** Useful raw data visualization. It shows the massive "Benue spike" which motivates the state-year fixed effects.
- **Labeling:** The callouts for "Benue law" and "SGF wave" are excellent and help the reader navigate the timeline.
- **Recommendation:** **REVISE**
  - **Specific Change:** Reduce the opacity (alpha) of the shaded confidence intervals even further, or switch to "spaghetti" lines for individual states in the background with thick group means in the foreground.

### Figure 4: "Randomization Inference: Distribution of Permuted Coefficients"
**Page:** 18
- **Formatting:** Standard histogram. The red dashed line for the observed effect is clear.
- **Clarity:** Good. The x-axis is well-scaled.
- **Storytelling:** Essential for showing the significance of the result given the small number of clusters (37 states).
- **Labeling:** Legend and axes are clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Leave-One-State-Out: DDD Coefficient Stability"
**Page:** 19
- **Formatting:** Very clean horizontal dot plot.
- **Clarity:** Excellent. The names of the excluded states are easy to read.
- **Storytelling:** Shows the result is not driven by the "headline" case of Benue. This is a very high-value robustness exhibit.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Robustness and Sensitivity Checks"
**Page:** 21
- **Formatting:** This is a "summary" table of other regressions. 
- **Clarity:** High. It allows the reader to see 9 different robustness checks in one view.
- **Storytelling:** Strong. It proves the "Deterrence" vs "Displacement" argument by showing the border-spillover and within-state displacement nulls.
- **Labeling:** Notes column is very helpful for explaining the variation in each row.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "DDD Event Study: Leads and Lags of Treatment x Pastoral"
**Page:** 21
- **Formatting:** Same style as Fig 1/2. 
- **Clarity:** This is the most important figure for the DDD identification. It is cleaner than Figure 1 because it removes state-level noise.
- **Storytelling:** This should be the primary figure of the paper. It shows an immediate, sustained drop.
- **Labeling:** Clear.
- **Recommendation:** **PROMOTE TO MAIN TEXT** (already in main text, but should be moved to appear *before* Figure 1, as it is the direct visualization of the paper's preferred specification).

### Table 4: "Effective Sample: State Contributions to DDD Identification"
**Page:** 22
- **Formatting:** Large, text-heavy table. 
- **Clarity:** Clear, but borderline "data dump."
- **Storytelling:** Crucial for transparency in DDD designs (which often lose a lot of the sample to fixed effects), but it interrupts the flow of the results.
- **Labeling:** Good.
- **Recommendation:** **MOVE TO APPENDIX**

### Table 5: "Callaway-Sant’Anna ATT Estimates: State-Year Level"
**Page:** 24
- **Formatting:** Tiny table (only 2 rows).
- **Clarity:** Clear.
- **Storytelling:** Redundant. These numbers are already visually represented in Figures 1 and 2.
- **Labeling:** Clear.
- **Recommendation:** **REMOVE** (Incorporate the N and ATT into the notes of Figure 1 and 2).

### Figure 7: "Within-State Displacement Test: Non-Pastoral LGAs in Treated States"
**Page:** 25
- **Formatting:** Consistent.
- **Clarity:** Good.
- **Storytelling:** Supports the "Deterrence" argument. 
- **Labeling:** Note is helpful.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Table 6: "Anti-Open Grazing Law Adoption by State"
**Page:** 36
- **Formatting:** Simple list.
- **Clarity:** High.
- **Storytelling:** Essential background data.
- **Labeling:** Good.
- **Recommendation:** **KEEP AS-IS**

### Figure 8: "Anti-Open Grazing Laws and Farmer-Herder Violence in Nigeria" (Map)
**Page:** 38
- **Formatting:** Professional GIS layout. Colors are distinguishable.
- **Clarity:** Excellent. The parenthetical numbers showing conflict counts are a great detail.
- **Storytelling:** Vital for the reader to understand the geography (Middle Belt vs South). 
- **Labeling:** Good legend.
- **Recommendation:** **PROMOTE TO MAIN TEXT** (This should be Figure 1 of the paper to set the scene).

---

## Overall Assessment

- **Exhibit count:** 5 main tables, 6 main figures, 1 appendix table, 1 appendix figure.
- **General quality:** Extremely high. The paper follows the "modern" style of conflict economics (e.g., similar to *Dube and Vargas* or *Bazzi and Blattman*).
- **Strongest exhibits:** Figure 5 (Leave-one-out) and Table 3 (Robustness summary).
- **Weakest exhibits:** Figure 3 (overlapping CIs) and Table 5 (redundant).
- **Missing exhibits:** A **Map of Pastoral vs. Non-Pastoral LGAs**. The paper relies heavily on this classification for the DDD, but we only see a state-level map. A sub-state map showing the "Pastoral" zones would be the most important addition.

**Top 3 improvements:**
1. **Rearrange Figures:** Promote the Map (Fig 8) to the Introduction or Data section. Move the DDD Event Study (Fig 6) to be the "lead" result figure, as it matches the preferred specification better than Figure 1.
2. **Sub-state Map:** Create a new figure showing the 193 LGAs classified as "Pastoral" to visually validate the "Middle Belt" and "Revealed Conflict" criteria.
3. **Table Consolidation:** Remove Table 5 (redundant) and move Table 4 (Effective Sample) to the Appendix to keep the Main Text focused on results rather than diagnostic overhead.