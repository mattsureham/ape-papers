# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-06T16:36:08.526826
**Route:** Direct Google API + PDF
**Tokens:** 19437 in / 1977 out
**Response SHA256:** aee663b0afe21284

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Summary Statistics by Distance to Nearest GPE Station"
**Page:** 11
- **Formatting:** Clean and professional. Follows the standard three-line table format (top, header, bottom).
- **Clarity:** Very high. The comparison between Control (>2km) and Treatment (0-1km) is immediately apparent.
- **Storytelling:** Essential. It justifies the use of commune fixed effects by showing the baseline differences (treatment areas are more expensive/denser).
- **Labeling:** Good. Includes units (EUR, m2, km). 
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Effect of GPE Construction on Residential Property Prices"
**Page:** 17
- **Formatting:** Professional. Standard errors are correctly placed in parentheses. Significance stars are defined.
- **Clarity:** Logical progression from simple DiD (Col 1-2) to phase decomposition (3-4) to subsample (5).
- **Storytelling:** This is the "money table" of the paper. It successfully shows that the negative effect is robust to controls and is actually stronger for apartments.
- **Labeling:** Clear. The note explains the difference between columns.
- **Recommendation:** **REVISE**
  - Change the header "Post-Construction x Within 1km" to "Active Construction" to match the text and Phase Decomposition terminology.
  - Add "Mean of Dep. Var." to the bottom of the table to help readers interpret the magnitude of log-point estimates.

### Figure 1: "Event Study: Property Prices Relative to Construction Start"
**Page:** 19
- **Formatting:** Good use of a reference line at $k=-1$. The shaded 95% CI is standard.
- **Clarity:** The message—that the effect builds over time post-treatment—is clear.
- **Storytelling:** Crucial for validating the parallel trends assumption (though the pre-period is short).
- **Labeling:** The red vertical "Construction Start" label is helpful. 
- **Recommendation:** **REVISE**
  - The y-axis label is "Coefficient (log price per m²)". Add the percentage equivalent on a right-side y-axis (e.g., -0.2 log points $\approx$ -18%) for faster parsing.
  - Increase the font size of the axis tick labels; they appear slightly small compared to the main text.

### Figure 2: "Construction Disamenity by Distance Ring"
**Page:** 21
- **Formatting:** Clean "coefficient plot" style.
- **Clarity:** Effectively shows the decay of the effect.
- **Storytelling:** Strong. It validates that the externality is localized, which helps rule out broader regional shocks.
- **Labeling:** "0-500m" etc. on the x-axis is clear.
- **Recommendation:** **KEEP AS-IS** (Consider merging with Table 5 if space is tight, but as a figure, it is very effective).

### Figure 3: "TWFE vs. Callaway–Sant’Anna Event Study"
**Page:** 22
- **Formatting:** Overlaying two event studies can be messy; here it is borderline.
- **Clarity:** The overlap of CIs makes it difficult to see the individual point estimates for the CS-DiD (red).
- **Storytelling:** Important for addresssing modern DiD concerns, but the "story" is just "the results are similar."
- **Recommendation:** **MOVE TO APPENDIX**
  - This is a methodological robustness check. While important for reviewers, it clutters the main results section. Move to Appendix and keep only the TWFE event study in the main text.

### Figure 4: "Leave-One-Line-Out Sensitivity"
**Page:** 23
- **Formatting:** Standard "jackknife" plot.
- **Clarity:** Very high.
- **Storytelling:** Demonstrates that no single line (e.g., a particularly noisy one) drives the result.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Construction-Phase Capitalization by GPE Line"
**Page:** 24
- **Formatting:** Consistent with Table 1.
- **Clarity:** High.
- **Storytelling:** This table reveals significant heterogeneity (Line 17 vs Line 14/15/16/17). It adds a layer of nuance to the "average" effect.
- **Labeling:** The note is clear.
- **Recommendation:** **REVISE**
  - Sort the rows by the "Estimate" column (from most negative to most positive) rather than the current arbitrary order. This makes the "winners and losers" easier to identify.

### Table 4: "Composition Test: Effect of Construction on Property Characteristics"
**Page:** 27
- **Formatting:** Good.
- **Clarity:** Simple and direct.
- **Storytelling:** Vital for the "mechanisms" section. It shows that the type of property selling changes, which justifies the hedonic controls in Table 2.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Figure 5: "Grand Paris Express Station Locations by Opening Year"
**Page:** 34
- **Formatting:** Standard lat/long plot.
- **Clarity:** Good for spatial context.
- **Storytelling:** Useful for readers unfamiliar with Paris geography.
- **Recommendation:** **REVISE**
  - Add a faint background map (e.g., commune borders or the Seine river) to provide spatial orientation. Dots in white space are hard to contextualize.

### Table 5: "Construction-Phase Capitalization by Distance Ring"
**Page:** 34
- **Clarity:** This is the tabular version of Figure 2.
- **Recommendation:** **REMOVE**
  - It is redundant with Figure 2. The point estimates and N are already discussed in the text or visible in the figure.

### Figure 6: "GPE Construction Timeline: Staggered Milestones by Line"
**Page:** 35
- **Formatting:** Excellent "Gantt-style" chart for staggered DiD.
- **Clarity:** Extremely high.
- **Storytelling:** This is actually one of the most important figures for explaining the identification strategy.
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - Place this in Section 2.2 or 4.1. It helps the reader understand the "staggered" nature of the treatment better than the text list on pages 4-5.

### Figure 7: "Raw Price Trends by Distance to Nearest GPE Station"
**Page:** 35
- **Formatting:** A bit cluttered. The "Within 500m" line is very volatile.
- **Clarity:** The "..." before the y-axis labels is non-standard.
- **Storytelling:** Intended to show raw trends, but the high volatility (likely due to small N in the 500m group per quarter) makes it look "noisy."
- **Recommendation:** **REVISE**
  - Remove the "Within 500m" line from this plot (it's too noisy for a "trends" argument) or use a 4-quarter moving average to smooth the lines and show the underlying trend.

---

## Overall Assessment

- **Exhibit count:** 4 main tables, 4 main figures, 1 appendix table, 3 appendix figures.
- **General quality:** The exhibits are highly professional and follow the "AER style" (clean, minimal lines, clear notes). The visual evidence for the main claim is robust.
- **Strongest exhibits:** Table 2 (Main Results), Figure 6 (Timeline - currently in Appendix).
- **Weakest exhibits:** Figure 7 (Raw Trends), Figure 3 (TWFE vs CS - too cluttered).

- **Missing exhibits:** 
  - **A Map of Treatment/Control:** A figure showing the 1km "treated" buffers vs. the >2km "control" areas on a real map of Ile-de-France would be much more powerful than the abstract Figure 5.
  - **Regression Specification Box:** Since you use several FE and control combinations, a small "Table Note" or footer in Table 2 explicitly listing the Hedonic Controls (Surface, Rooms, etc.) is better than just "X".

- **Top 3 improvements:**
  1. **Spatial Context:** Replace Figure 5 with a proper map showing the treatment/control spatial split (the "donut hole" design).
  2. **Promote Figure 6:** Move the staggered timeline figure to the main text; it is the best way to visualize your identification.
  3. **Visual Smoothing:** Clean up Figure 7 (Raw Trends) to show the "parallelism" more clearly, perhaps by pooling the treatment groups or smoothing the quarterly noise.