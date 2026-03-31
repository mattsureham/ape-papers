# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-31T03:33:31.745780
**Route:** Direct Google API + PDF
**Tokens:** 18917 in / 2062 out
**Response SHA256:** 1c3871d557935b0b

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Table 1: "Policy Regimes at the 10 kWp Threshold"
**Page:** 6
- **Formatting:** Professional and clean. Use of horizontal rules is appropriate for top-tier journals.
- **Clarity:** Excellent. It serves as a "roadmap" for the identification strategy.
- **Storytelling:** Vital. It defines the "four-break" natural experiment.
- **Labeling:** Clear. The "Incentive at 10 kWp" column effectively translates policy into economic theory (kink vs. notch).
- **Recommendation:** **KEEP AS-IS**

### Table 2: "Summary Statistics: Rooftop Solar Installations by Policy Period"
**Page:** 10
- **Formatting:** Standard. Numbers are well-aligned.
- **Clarity:** Good, though "Mean Modules" and "Module Coverage" feel secondary to the capacity story.
- **Storytelling:** Useful for showing the scale of the data (N > 3 million).
- **Labeling:** Note clarifies the sample restrictions clearly.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Bunching Estimates at the 10 kWp Threshold by Policy Period"
**Page:** 13
- **Formatting:** High quality. Decimal alignment is perfect.
- **Clarity:** High. Grouping by policy period allows the reader to see the "treatment" effect immediately.
- **Storytelling:** This is the "money table." The jump from 1.8 to 86.5 and back to 10.4 is the core result.
- **Labeling:** Bootstrap replications and CI definitions are properly noted.
- **Recommendation:** **KEEP AS-IS**

### Table 4: "Annual Bunching Ratios at 10 kWp, 2008–2024"
**Page:** 14
- **Formatting:** Journal-ready.
- **Clarity:** The columns $N_{9.9}$ and $N_{10.1}$ provide a raw-data reality check that is very powerful (e.g., seeing 26,527 vs 11 in 2020).
- **Storytelling:** Provides the granular evidence for the "step-function" claim.
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - Minor: Bold the years where policy changes occur (2012, 2014, 2021) to help the reader's eye track the "breaks" described in the text.

### Figure 1: "Density of Rooftop Solar Installations Near 10 kWp: Four Policy Periods"
**Page:** 15
- **Formatting:** Clean. High-contrast colors.
- **Clarity:** The "Surcharge" line (orange) clearly dominates the visual field, which is appropriate.
- **Storytelling:** Excellent visual proof of the "missing middle."
- **Labeling:** Axis labels are clear. The vertical dashed line for the threshold is helpful.
- **Recommendation:** **KEEP AS-IS**

### Figure 2: "Annual Bunching Ratio at 10 kWp, 2008–2024"
**Page:** 16
- **Formatting:** Modern bar chart. 
- **Clarity:** Very high. The color coding matches the policy regimes in Table 1.
- **Storytelling:** This is arguably the most impactful figure in the paper. It makes the "trap" vs. "reform" story undeniable.
- **Labeling:** The y-axis "Bunching Ratio (b)" is clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Monthly Bunching Ratio at 10 kWp, 2013–2024..."
**Page:** 17
- **Formatting:** Good use of shaded confidence bands.
- **Clarity:** A bit cluttered due to the density of monthly data points, but necessary for the "timing" argument.
- **Storytelling:** Essential for showing the *lack* of anticipation for the 2014 notch compared to the gradual adjustment in 2021.
- **Labeling:** Vertical event lines are well-labeled.
- **Recommendation:** **KEEP AS-IS**

### Table 5: "Pre-Specified Estimator Family: Surcharge Period (2014–2020)"
**Page:** 18
- **Formatting:** Standard.
- **Clarity:** The "Mass Balance" column is only populated for one row; this looks slightly "broken" visually.
- **Storytelling:** Demonstrates that the result isn't a fluke of a specific polynomial degree.
- **Labeling:** Notes are comprehensive.
- **Recommendation:** **MOVE TO APPENDIX**
  - This is a robustness check. The range (52–98) is already cited in the text and Table 3. Moving this frees up space for mechanism evidence.

### Figure 4: "Observed vs. Counterfactual Density: Surcharge Period (2014–2020)"
**Page:** 19
- **Formatting:** Standard bunching plot.
- **Clarity:** The shaded "Excess mass" area is clear.
- **Storytelling:** Standard for bunching papers (Chetty/Saez style).
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 5: "Module Count Distribution: Systems Near 10 kWp (2014–2020)"
**Page:** 20
- **Formatting:** Clear bar chart.
- **Clarity:** The "missing" bars above 40 modules for "Below 10 kWp" systems is the key.
- **Storytelling:** Proves the mechanism is physical downsizing (removing panels) rather than reporting fraud.
- **Labeling:** Needs a unit for the x-axis ("Count" or "Modules").
- **Recommendation:** **KEEP AS-IS**

---

## Appendix Exhibits

### Figure 7: "Specification Curve: Bunching Ratio Across Estimator Choices"
**Page:** 29
- **Formatting:** Professional.
- **Clarity:** Shows the sensitivity clearly.
- **Recommendation:** **KEEP AS-IS**

### Figure 8: "Density of Solar Installations Near 30 kWp Threshold..."
**Page:** 30
- **Formatting:** Consistent with Figure 1.
- **Clarity:** Slightly more "noisy" than the 10 kWp plot, which justifies its place in the appendix.
- **Recommendation:** **KEEP AS-IS**

### Figure 9: "Installation Type Placebo: Rooftop vs. Ground-Mount"
**Page:** 31
- **Clarity:** The contrast is stark. 
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - This is a powerful placebo test. Showing that ground-mounts (which don't consume their own power and thus don't care about the surcharge) do NOT bunch is a "smoking gun" for the policy being the driver.

### Table 6: "Mechanism Evidence: Kink–Notch Decomposition and Module Counts"
**Page:** 32
- **Storytelling:** This table is actually very important for the "Expert Intermediary" and "Modularity" arguments.
- **Recommendation:** **PROMOTE TO MAIN TEXT**
  - Panel B's granular module counts per bin are stronger evidence for the "discrete removal" theory than the text alone.

### Table 8, 9, 10: "Robustness and Effect Sizes"
**Pages:** 33–34
- **Recommendation:** **KEEP AS-IS** (in Appendix). These are standard "due diligence" tables.

---

## Overall Assessment

- **Exhibit count:** 5 Main Tables (suggested 4), 5 Main Figures (suggested 6), 5 Appendix Tables, 3 Appendix Figures.
- **General quality:** Extremely high. The figures are modern, clean, and follow the aesthetic of top-tier journals like the AEJs or QJE. The tables are "clean" (Blackwell/AER style).
- **Strongest exhibits:** Figure 2 (The "Timeline" of bunching) and Figure 1 (The "Missing Middle" overlay).
- **Weakest exhibits:** Table 5 (redundant with text) and Table 9 (Standardized Effect Sizes—not very informative in a bunching context).
- **Missing exhibits:** A **Map** showing the geographic uniformity mentioned in Section 6.4. While Figure 6 (the dot plot) is good, a heat map of bunching intensity by German postal code would visually "hammer home" the nationally integrated installer market.

**Top 3 Improvements:**
1.  **Promote the Placebo:** Move Figure 9 (Rooftop vs. Ground-Mount) to the main text. It is your strongest evidence against "technology" being the driver.
2.  **Consolidate Table 3 and 5:** Integrate the "Range" and "Median" from the estimator family into the notes of Table 3, and move the full Table 5 to the appendix.
3.  **Enhance Table 4:** Use bolding or background shading for rows representing different policy regimes to make the "Four-Break" design visually intuitive within the data table.