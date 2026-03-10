# Exhibit Review — Gemini 3 Flash (Round 2)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-10T15:49:07.857697
**Route:** Direct Google API + PDF
**Tokens:** 18397 in / 2065 out
**Response SHA256:** 10f0390dadcf59b0

---

This review evaluates the visual exhibits of "The Symmetric Test: Drug Decriminalization and Recriminalization in Oregon" against the standards of top-tier economics journals (AER, QJE, etc.).

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics: Drug Overdose Death Rates by Phase"
**Page:** 7
- **Formatting:** Clean and professional. Uses standard booktabs style. Numbers are clearly legible, though not perfectly decimal-aligned.
- **Clarity:** Excellent. Comparison between Oregon and "Other States" across specific time regimes is logical.
- **Storytelling:** Crucial. It establishes the baseline "pre-treatment" difference (Oregon was much lower) and the "fentanyl catch-up" narrative.
- **Labeling:** Clear. The note defines the phases and data sources.
- **Recommendation:** **KEEP AS-IS**

### Figure 1: "Design 1: Oregon vs. Synthetic Oregon (Decriminalization)"
**Page:** 12
- **Formatting:** Standard SCM plot. The colors (red/blue) are classic but should be checked for grayscale legibility. Gridlines are subtle.
- **Clarity:** The divergence after Measure 110 is immediately visible.
- **Storytelling:** The primary "Design 1" result.
- **Labeling:** Y-axis is clearly labeled. Dotted line for treatment is standard.
- **Recommendation:** **REVISE**
  - **Change:** Add a second vertical dotted line for the *announcement* of the policy or the start of the "fentanyl wave" mentioned in the text to visually test the "coincidence" argument.

### Figure 2: "Design 1: Treatment Effect Over Time (Gap Plot)"
**Page:** 13
- **Formatting:** Clean. Horizontal dashed line at zero is essential.
- **Clarity:** Shows the "inverted-U" shape discussed in the text.
- **Storytelling:** Good, but potentially redundant with Figure 1. In top journals, Figures 1 and 2 are often combined into a two-panel figure (Panel A: Raw levels, Panel B: Gaps).
- **Labeling:** Correct.
- **Recommendation:** **REVISE**
  - **Change:** Consolidate Figures 1 and 2 into a single "Figure 1" with Panel A and Panel B. This saves space and keeps the level/gap comparison together.

### Table 2: "Synthetic Control Weights: Design 1 (Top Donors)"
**Page:** 14
- **Formatting:** Minimalist and professional.
- **Clarity:** Very high.
- **Storytelling:** Necessary for SCM transparency. It shows California's dominance, which supports the "Pacific Coast" confounding argument.
- **Labeling:** Notes are helpful.
- **Recommendation:** **KEEP AS-IS** (Could be moved to Appendix if space is tight, but top journals usually want the weights in the main text).

### Figure 3: "Permutation Inference: Design 1"
**Page:** 15
- **Formatting:** Modern histogram style.
- **Clarity:** The red bar for Oregon effectively shows it as an outlier.
- **Storytelling:** Essential for establishing statistical significance in SCM papers.
- **Labeling:** X-axis units (Deaths per 100K) are present.
- **Recommendation:** **KEEP AS-IS**

### Figure 4: "Design 2: Oregon vs. Synthetic Oregon (Recriminalization)"
**Page:** 16
- **Formatting:** Matches Figure 1.
- **Clarity:** Clear divergence in the opposite direction.
- **Storytelling:** The second half of the "Symmetric Test."
- **Labeling:** Proper.
- **Recommendation:** **REVISE**
  - **Change:** Since this is a "Symmetric Test" paper, consider making Figure 1, Figure 4, and Figure 5 (the combined plot) a single multi-panel exhibit to force the reader to see the "symmetry" in one place.

### Table 3: "Main Results: Synthetic Control Estimates"
**Page:** 17
- **Formatting:** Professional. Good use of parentheses for SEs.
- **Clarity:** This is the "money table." It provides the point estimates for all three designs.
- **Storytelling:** Central to the paper. The $\hat{\tau}_{sum}$ row is the key contribution.
- **Labeling:** Excellent. Defines N, units, and significance stars.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "The Symmetric Test: Combined Gap Plots from Both Designs"
**Page:** 18
- **Formatting:** The two lines are distinct.
- **Clarity:** A bit cluttered where the lines overlap.
- **Storytelling:** This is the most "original" visual in the paper, illustrating the core methodological contribution.
- **Labeling:** Legends are clear.
- **Recommendation:** **REVISE**
  - **Change:** Add a "zero-crossing" annotation. The text says the sum is indistinguishable from zero; a visual indicator of where the blue line "cancels" the red line would be powerful.

### Table 4: "Drug Decomposition: Decriminalization Effect by Drug Category"
**Page:** 19
- **Formatting:** Clean.
- **Clarity:** The "Share of Total" column makes the 83% fentanyl finding pop.
- **Storytelling:** This table "breaks" the causal decriminalization story by showing the fentanyl dominance.
- **Labeling:** Informative notes regarding overlapping categories.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "Drug-Specific Decomposition of the Decriminalization Effect"
**Page:** 20
- **Formatting:** Standard bar chart.
- **Clarity:** High.
- **Storytelling:** Redundant with Table 4. Economics journals usually prefer either a table or a figure for these results, rarely both unless the figure adds a dimension (like confidence intervals, which this lacks).
- **Recommendation:** **REMOVE** (The data is already in Table 4, and the figure adds no new information/inference).

### Figure 7: "Fentanyl Exposure: Oregon vs. National Average"
**Page:** 21
- **Formatting:** Matches previous line plots.
- **Clarity:** Very clear "catch-up" visual.
- **Storytelling:** Vital for the "Interpretation B" (confounding) argument.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Table 5: "Robustness: Design 1 Under Alternative Specifications"
**Page:** 31
- **Formatting:** Standard.
- **Clarity:** Good.
- **Storytelling:** Validates that the results aren't cherry-picked.
- **Labeling:** Notes are comprehensive.
- **Recommendation:** **KEEP AS-IS**

### Figure 8: "Oregon vs. National Average Overdose Rate"
**Page:** 32
- **Formatting:** Shaded IQR is a nice touch.
- **Clarity:** This is actually a very strong "raw data" figure.
- **Storytelling:** It shows that Oregon was an outlier in terms of *trajectory*, not just level.
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - Many reviewers want to see the "raw data" (Oregon vs. Mean of others) before seeing the SCM counterfactual. This should be Figure 1.

### Table 6: "Standardized Effect Sizes for Main Outcomes"
**Page:** 33
- **Formatting:** A bit text-heavy in the "Classification" column.
- **Clarity:** Good for cross-study comparison.
- **Storytelling:** Secondary to the main analysis.
- **Labeling:** Descriptive.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 3 Main Tables, 7 Main Figures, 2 Appendix Tables, 1 Appendix Figure.
- **General quality:** High. The formatting is consistent with top-tier journals. The logic of the exhibit order follows the narrative of the paper well.
- **Strongest exhibits:** Table 3 (The results summary) and Figure 5 (The symmetric visual).
- **Weakest exhibits:** Figure 6 (Redundant) and Figure 2 (Better as a panel of Figure 1).
- **Missing exhibits:** A **Donor Weights Table for Design 2**. You provided weights for Design 1 (Table 2) but not for the recriminalization design. Transparency requires both.

**Top 3 Improvements:**
1. **Consolidate and Panel:** Group related figures. Combine Levels and Gaps (Fig 1 & 2) into one exhibit. Combine the two Designs (Fig 1 & 4) into a panel structure. This makes the "Symmetry" easier to see.
2. **Promote Raw Data:** Move Figure 8 (Oregon vs. National Average) to the very beginning of the Results section. It provides the essential "Why do we need SCM?" motivation.
3. **Harmonize Inference:** Figure 6 was removed because it lacked confidence intervals. If the author can solve the "convergence issues" mentioned in the Figure 6 note, a bar chart *with* error bars would be much more powerful than Table 4. If not, stick to the table.