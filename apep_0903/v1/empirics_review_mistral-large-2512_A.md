# V1 Empirics Check — mistralai/mistral-large-2512 (Variant A)

**Model:** mistralai/mistral-large-2512
**Variant:** A
**Date:** 2026-03-25T10:57:51.815215

---

### 1. Idea Fidelity

The paper adheres closely to the original idea manifest. It successfully exploits the sharp 20% threshold in the Swiss Second Home Initiative to test whether the ban converted housing stock toward permanent residents, using the Federal Housing Inventory data as specified. The identification strategy (sharp RDD at the 20% cutoff) and key outcomes (second-home share, primary-home share, dwelling growth) align perfectly with the manifest. The paper also incorporates the suggested robustness checks (McCrary density test, placebo cutoffs, donut specifications) and extends the analysis with dynamic effects and mechanism discussions.

One minor deviation is the focus on the *change* in second-home share (from 2017 to 2025) as the primary outcome, rather than the level. While this is a defensible choice (given the panel structure), the manifest did not explicitly specify whether levels or changes would be analyzed. However, the paper justifies this approach and shows that results are consistent for both levels and changes (Table 1, Column 3).

### 2. Summary

This paper evaluates the causal effect of Switzerland’s 2012 Second Home Initiative—a ban on new second-home construction in municipalities exceeding a 20% second-home share—on housing composition. Using a sharp regression discontinuity design (RDD) at the 20% threshold and federal housing inventory data (2017–2025), the authors find precisely estimated null effects: the ban did not convert second homes to primary residences, despite reducing total dwelling growth. The results are robust to extensive specification checks and suggest that quantity restrictions on housing supply freeze development without altering the use of existing stock.

### 3. Essential Points

**Critical Issue 1: Treatment Timing and Running Variable Measurement**
The paper uses the *initial* (2017) second-home share as the running variable to assign treatment, but the policy was enacted in 2012 and implemented in 2016. This creates two potential problems:
- **Endogeneity of the running variable**: If municipalities above the threshold responded to the ban by reducing their second-home share *before* 2017 (e.g., through exemptions or misreporting), the 2017 share may not reflect the "true" pre-treatment share. This could bias the RDD estimates toward zero.
- **Dynamic sorting**: Municipalities near the threshold may have strategically adjusted their housing stock between 2012 and 2017 to avoid the ban, violating the continuity assumption.

*Constructive suggestion*: The authors should:
1. Show the distribution of second-home shares *pre-2012* (if data exist) to test for pre-trend manipulation.
2. Justify why the 2017 share is the appropriate running variable (e.g., argue that exemptions/loopholes limited pre-2017 adjustments).
3. Consider an alternative specification where treatment is assigned based on the *2012* share (if data are available) to address potential sorting.

---

**Critical Issue 2: Interpretation of the Null Result**
The paper interprets the null effect as evidence that the ban "failed to convert existing stock." However, the RDD estimates the *local average treatment effect* (LATE) at the 20% threshold, not the average treatment effect (ATE) for all treated municipalities. The 340 municipalities above the threshold are heterogeneous (e.g., some have 40%+ second-home shares), and the effect may vary with distance from the cutoff. The null at the threshold does not rule out meaningful effects in municipalities far above 20%.

*Constructive suggestion*: The authors should:
1. Clarify that the RDD identifies the LATE at the threshold, not the ATE for all treated municipalities.
2. Test for heterogeneity in treatment effects by interacting the treatment indicator with the distance from the threshold (e.g., using a "kink" RDD or subsample analysis).
3. Discuss whether the null at the threshold is surprising given the policy’s exemptions (e.g., renovations, tourist rentals), which may have blunted effects near the cutoff.

---

**Critical Issue 3: Mechanism and External Validity**
The paper argues that the ban failed because it targeted new supply, not existing stock, and because exemptions (e.g., renovations, tourist rentals) maintained avenues for second-home investment. However, the analysis does not directly test these mechanisms. For example:
- Did municipalities above the threshold exploit exemptions more than those below?
- Did the ban reduce *new* second-home construction (as opposed to total dwelling growth)?
- Did the policy affect rental markets or vacancy rates, which could indirectly influence stock conversion?

*Constructive suggestion*: The authors should:
1. Add a table or figure showing trends in *new* second-home construction (if data exist) to test whether the ban reduced the flow of vacation homes.
2. Analyze vacancy rates or hotel overnight stays (as mentioned in the manifest) to assess whether the ban affected housing utilization.
3. Discuss whether the Swiss context (e.g., strong property rights, exemptions) limits generalizability to other settings (e.g., Barcelona’s short-term rental bans).

---

### 4. Suggestions

**Data and Measurement**
1. **Pre-trend analysis**: If pre-2012 data are unavailable, the authors should acknowledge this limitation and discuss whether post-2012 adjustments (e.g., exemptions) could have biased the running variable.
2. **Alternative outcomes**: The manifest mentions empty dwelling rates and hotel overnight stays. These could be added as secondary outcomes to test for indirect effects (e.g., reduced vacancy rates or increased tourism pressure).
3. **Municipal mergers**: The paper notes that the number of municipalities varies across waves due to mergers. The authors should clarify how mergers are handled (e.g., are merged municipalities treated as new units or are pre-merger data aggregated?).

**Empirical Strategy**
4. **Covariate balance**: The paper does not show covariate balance at the threshold. Adding a table or figure (e.g., using `rdplot` in Stata) would strengthen the continuity assumption.
5. **Bandwidth selection**: The MSE-optimal bandwidth (5.85 pp) is wide relative to the threshold (20%). The authors should discuss whether this bandwidth is appropriate given the density of municipalities near the cutoff (e.g., 78 in 18–22%).
6. **Alternative specifications**: The paper could explore:
   - A *fuzzy* RDD if compliance with the ban was imperfect (e.g., some municipalities above 20% continued to approve second homes).
   - A difference-in-discontinuities (DiDiD) design to exploit the 2024 policy relaxation as a secondary cutoff.

**Interpretation and Generalizability**
7. **Heterogeneous effects**: The paper could test whether the ban had larger effects in municipalities with:
   - Higher baseline second-home shares (e.g., >30%).
   - Stronger tourism economies (e.g., higher hotel overnight stays).
   - Fewer exemptions (e.g., limited renovation rights).
8. **Comparison to Hilber and Schöni (2020)**: The paper contrasts its null result with Hilber and Schöni’s findings of price declines and unemployment increases. The authors should discuss whether these effects are consistent with a "frozen development" mechanism (e.g., reduced construction activity without stock conversion).
9. **Policy implications**: The paper argues that demand-side instruments (e.g., vacancy taxes) may be more effective than supply-side bans. This could be strengthened by:
   - Citing evidence from other contexts (e.g., Vancouver’s empty homes tax).
   - Discussing whether Switzerland’s exemptions (e.g., tourist rentals) are common in other countries.

**Presentation and Clarity**
10. **Figures**: The paper lacks visualizations of the RDD. Adding figures showing:
    - The density of the running variable (with the McCrary test).
    - The RDD plot for the main outcome (change in second-home share).
    - Event-study coefficients (Table 4) as a plot.
    would improve clarity.
11. **Table formatting**: Some tables (e.g., Table 3) are dense. The authors could:
    - Split Table 3 into separate tables for bandwidth sensitivity, donut RDD, and placebo cutoffs.
    - Add a column for the number of treated/control municipalities in each specification.
12. **Abstract**: The abstract could be more precise about the null result (e.g., "the 95% confidence interval rules out effects larger than 2.4 percentage points"). The current phrasing ("no detectable effect") is vague.

**Minor Issues**
13. **Typo**: In Table 1, the note for Column (3) says "secondary home share level in 2025 (%)" but the outcome is labeled "Sec. Share Level (%)" in the header.
14. **JEL codes**: The paper uses R31, R38, and R52. Consider adding R21 (Urban, Rural, Regional, and Transportation Economics: Housing Demand) or R23 (Regional Migration; Regional Labor Markets; Population).
15. **Acknowledgments**: The acknowledgments section is unusual for an AER: Insights paper (e.g., "autonomously generated"). The authors should follow standard disclosure practices (e.g., funding sources, data availability).

### Overall Assessment
This is a well-executed paper with a credible identification strategy and a novel contribution to the literature on housing regulation. The null result is precisely estimated and robust, but the authors must address the three critical issues above to strengthen the causal interpretation and policy implications. With revisions, this paper would be a strong candidate for publication in AER: Insights.
