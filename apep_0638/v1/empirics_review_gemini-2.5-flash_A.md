# V1 Empirics Check — google/gemini-2.5-flash (Variant A)

**Model:** google/gemini-2.5-flash
**Variant:** A
**Date:** 2026-03-13T17:37:40.912237

---

## Referee Report: The Saturday Soldier: Labor Market Returns to Mexico's Compulsory Military Lottery

This paper investigates the labor market effects of Mexico’s compulsory military lottery, the *Sorteo Militar*, which randomly assigns 18-year-old men to active Saturday training or reserve status. Exploiting the gender-specific nature of this program, the author uses a male-female age-profile difference-in-differences (DiD) design with data from INEGI’s ENOE survey (2018-2019). The main finding is that lottery eligibility significantly increases male employment and formal employment, but has no effect on conditional earnings or school enrollment. The author proposes a mechanism of "formalization through credentialing," where the *cartilla militar* (military service booklet) facilitates access to formal-sector jobs.

Overall, this is a highly promising and potentially impactful paper. The identification strategy is transparent and clever, leveraging a substantial and previously unexploited natural experiment. The novelty, scale, and policy relevance of this setting are particularly appealing. The paper is clearly written and concise, as expected for an AER: Insights format. While the core findings are compelling, a few critical issues need to be addressed, and several suggestions could further strengthen the analysis and interpretation.

---

### 1. Idea Fidelity

The paper adheres remarkably well to the original "Idea Manifest."

*   **Research Question:** The core research question regarding the returns to compulsory weekend service on employment, earnings, and education is directly addressed.
*   **Identification Strategy:** The primary "Male-Female DiD at Age 18" strategy is implemented exactly as described, forming the backbone of the paper. This is correctly identified as the main identification strategy. The manifest's mention of "Age Discontinuity at 18" also aligns perfectly with the DiD approach at this age threshold. The paper also discusses the "2025 policy shock" as a future validation, reflecting the manifest's point.
*   **Data Source:** The paper uses INEGI's ENOE labor force survey, as intended, and confirms accessibility and variable availability.
*   **Variables:** The paper utilizes the key outcome variables (employment, earnings, hours, education, social security for formality, occupational position) exactly as outlined in the manifest.
*   **Novelty & Scale:** The paper correctly emphasizes the novelty, massive scale, and unique "minimal service intensity" aspect of the Mexican lottery, which were central to the original idea. The comparison to other conscription literature is apt.
*   **Feasibility Checks:** The paper demonstrates the feasibility by successfully accessing and analyzing initial ENOE data, mirroring the "smoke test" log.

The paper does not explicitly pursue the "Cross-Municipality Treatment Intensity IV" (Strategy B from the manifest) or fully exploit birth month variation (from Strategy C) as distinct strategies. However, given the strong male-female DiD approach and the AER: Insights format constraints, this is a reasonable simplification. The core identification strategy is faithfully executed. The focus on the "cartilla militar" as the mechanism is also well-developed from the manifest's initial ideas.

---

### 2. Summary

This paper presents the first economic analysis of Mexico's large-scale, randomized military lottery (*Sorteo Militar*). Using a male-female difference-in-differences design around age 18, the study finds that lottery eligibility significantly boosts male employment (13.6 percentage points) and formal employment (11.6 percentage points) while having no impact on earnings or school enrollment. The mechanism proposed is a credentialing effect of the *cartilla militar* (military service booklet), which unlocks access to formal-sector jobs for young men.

---

### 3. Essential Points

1.  **Credibility of the "Post18" Threshold and its Interpretation:** The current setup of equation (2) defines `Post18` as `Age >= 18`. This implicitly assumes that the *full effect* of the lottery materializes at age 18 and persists, and lumps together the immediate effect with the cumulative effects at older ages (up to 30). This significantly conflates the ITT, especially as the lottery's service period (44 Saturdays over 10 months) occurs *after* age 18.
    *   **Actionable Issue:** The "Post18" variable is not a true post-treatment indicator in terms of when service *starts* or *ends*. The lottery happens *at* 18. Service starts *after* 18 (e.g., in the year they turn 19 or throughout their 19th year). The reported ITT of 0.136 pp for "Post-Lottery" (ages 18-30) is an *average* effect over a long window, not an immediate effect of eligibility. The event study is much more informative here. The main summary specification needs to focus on the period when treatment *could plausibly begin to affect outcomes*. A `Post19` or `Post20` would be more appropriate for a single summary coefficient, or just rely on the event-study coefficients for interpretation. The current `Post18` estimate is a mixture of a pre-period for actual service and a post-period for others, which introduces bias if the parallel trends assumption does not hold for the entire `[18, 30]` range.
    *   **Suggestion:** Change the main DiD specification (Equation 2) to use `PostService = ind[Age >= 19 or Age >= 20]` (depending on when service is typically completed) to more accurately capture the effect of service, rather than eligibility alone. Or, as an alternative, focus the main `beta` on the age 18 coefficient from the event study (representing eligibility and immediate aftermath), and separate out the later effects explicitly. The current "Post-Lottery" definition for the quantitative summary results is problematic for direct causal interpretation as "the effect of the lottery."

2.  **LATE Scaling and its Sensitivity:** The paper reports a LATE scaled by a 40% treatment share. This is a crucial parameter, and its approximation warrants more careful justification and potentially sensitivity analysis.
    *   **Actionable Issue:** The statement "approximately 40% of men in each cohort assigned to active Saturday training (``white ball'')" and the scaling by exactly 0.40 are presented with certainty, but the text also mentions "enforcement varies by region" and "the exact share varies by year and state" in the limitations. Given that actual compliance might deviate and the probability might not be perfectly uniform, the 0.40 scaling factor requires more robust evidence. Does 40% reflect assignment probability or *actual service completion*? The LATE usually requires the latter. If some assigned to active duty don't complete, or if some assigned to reserve status complete service (e.g., through voluntary enlistment or other paths to a cartilla), the 0.40 factor could be off.
    *   **Suggestion:** Clarify if `0.40` is the *assignment probability* or the *treatment compliance rate*. If it's assignment, discuss potential compliance issues more deeply. Provide more detail on the source of the 40% figure, and ideally, show sensitivity of the LATE estimate to reasonable variations in this share (e.g., 35-45%). This is especially important as the LATEs are quite large.

3.  **Distinguishing "Credentialing" from "Hard Skill/Soft Skill" Acquisition:** The paper posits a strong mechanism: "formalization through credentialing," largely dismissing human capital acquisition. While compelling, the service itself (44 Saturday sessions of drilling, first aid, civic instruction) could plausibly impart some soft skills (discipline, teamwork, basic first aid) that are valued in the labor market.
    *   **Actionable Issue:** The argument for "formalization, not human capital" is persuasive given the null earnings effect. However, the exact distinction is tricky. Could the "cartilla" simply be the *signal* for these soft skills? Or is it truly a pure bureaucratic credential with no human capital content? While formal earnings are null, is there any evidence regarding specific job types, or promotions? If the LATE gets men into "entry-level formal jobs," do these jobs have different skill requirements than their informal counterparts?
    *   **Suggestion:** Acknowledge more carefully the potential for "general human capital" spill-overs (e.g., enhanced discipline, reliability) that might not translate to higher wages *within* a job but could facilitate *access* to certain kinds of jobs. Could the authors examine job types or career trajectories? Also, the paper notes "Men who draw black balls receive a different stamp (reserve status) on their cartilla, which satisfies some but not all credential requirements." Could this "partial credential" have a lesser effect? This might be an avenue for future work or a point for more nuanced discussion.

---

### 4. Suggestions

**Identification and Econometrics:**

1.  **Age-Binning for Event Study:** The event study table (Table 2) shows individual age coefficients up to age 25. Given that ENOE is a quarterly survey, there are actually four cohorts turning 18 in any given year. For example, some 18-year-olds might have just turned 18, while others are about to turn 19. Using single-year event times is common, but it can mask finer dynamics around the exact lottery eligibility and service commencement. Could the event study be refined, perhaps by grouping ages after 25 or showing a graph for visual clarity? Also, specifying `Age=17` as the reference year is good, but the event-study table shows `Age = 17` appearing multiple times as `[ref]`, which is confusing. This should be fixed.

2.  **Clustering of Standard Errors:** Standard errors are clustered by state. While this is a common practice, given the DiD design, it might be worth considering clustering at a higher level (e.g., state-year-quarter) if there's reason to believe that the error terms are correlated within these groups, or even wild cluster bootstrapping if the number of clusters (32 states) is a concern for asymptotic validity.

3.  **Parallel Trends Assumption:** While the pre-lottery coefficients in the event study appear statistically insignificant, reinforcing the parallel trends assumption, a formal placebo test could be beneficial. For example, testing the male-female DiD at an earlier age (e.g., "age 16 eligibility") and showing a null effect would further strengthen confidence. The paper does mention a partial placebo ("If the male-female gap shift at age 18 is driven by the Sorteo, there should be no analogous jump for women"), but this is an informal visual check rather than a test on the interaction coefficients.

4.  **Inclusion of Controls (Beyond FEs):** The paper uses age, year-quarter, and state fixed effects. While this is a strong baseline, including individual-level controls (e.g., education, marital status, parental education) could increase precision, particularly if they are differentially distributed across genders within age groups. The paper notes that education is a "bad control" if schooling decisions are affected, but if educational attainment is relatively fixed by say, age 16-17 then it could be useful. The robustness check shows that controlling for education does not change the result, which is reassuring. Clarify if those controls were included in the main specification or purely for robustness.

**Data and Measurement:**

5.  **Quarterly Data and Age Definition:** The ENOE is quarterly. Does `Age` refer to age at the time of the survey, or birth year? If it’s age at survey, then individuals interviewed in different quarters of their 18th year might be at different stages relative to the November lottery. For example, an 18-year-old surveyed in 2018Q1 or Q2 would not yet have participated in the November 2018 lottery, but one surveyed in Q4 2018 or Q1 2019 might have just drawn their ball. How exactly is `Age 18` defined in relation to the lottery? This might introduce noise or subtle misidentification if not handled carefully. The paper mentions `nac_anio` (birth year) in the manifest, but it's not clear how it's used to construct age relative to the lottery timing.

6.  **"Formal Employment" Definition:** While "social security access" is a standard and robust measure of formality in Mexico, the discussion should briefly acknowledge any nuances or limitations (e.g., some informal workers might have social security through a spouse or prior formal employment, or vice-versa).

7.  **Summary Statistics:** Table 1 is helpful. It would be insightful to add the standard deviations for the continuous variables to allow for better comparison of effect sizes relative to baseline variation in the summary stats directly, beyond the standardized effect sizes in the appendix.

**Interpretation and Discussion:**

8.  **The "2025 Regime Change":** The 2025 policy change (40% to 95% active assignment) is a fantastic natural validation. While not directly usable in this paper, emphasizing it as a direction for future research or a strong testable implication for *this* paper’s mechanism would be excellent. The wording in the paper ("natural dosage validation: the male-female gap at age 18 should increase by a factor of 0.95/0.40 ≈ 2.4") correctly links it to the identified mechanism.

9.  **Mechanism Depth: Cartilla vs. Experience:** While the paper leans heavily on the "cartilla as credential," it's also true that active service implies contact with a formal institution, possibly some networking, or exposure to a different social environment even for just 44 Saturdays. Could the "soft skills" for formality be about navigating bureaucracy, or understanding the expectations of formal employers? This could be part of the "formalization" without being purely about the certificate. Expand on this nuance slightly.

10. **Limitations Section:** The current limitations section is concise.
    *   Regarding the first point ("The DiD approach identifies the combined effect of all gender-specific age-18 events, not only the lottery"): While legal majority, voting, etc., affect both genders, there could be *gendered social norms* that kick in at legal adulthood for men vs. women (e.g. pressure for men to start contributing, women to marry). This is a well-known challenge for such DiD designs and warrants a brief acknowledgment that its perfect "treatment of men only" assumption, while strong, may not be perfect in terms of social expectations.
    *   Regarding the 40% treatment share: Strengthen the discussion here as noted in Essential Point 2.

11. **Broader Context and Policy Implications:** The paper discusses the contrast with other conscription studies effectively. The policy implications could be elaborated further, especially regarding the trade-offs. If the *cartilla* is the key, what are the costs and benefits of using mandatory military service as a formalization credential? Could there be less burdensome ways to achieve this formalization, or are there unintended negative consequences of linking a civic duty to labor market access?

12. **Presentation:**
    *   The use of `[ref]` several times for Age 17 in Table 2 is a formatting issue that needs to be fixed.
    *   The $R^2$ values are generally low, as is typical for microdata, but perhaps for the `In School` outcome, an $R^2$ of 0.000 is particularly low and stands out.

In conclusion, this is an excellent paper with a strong, novel identification strategy and compelling results. Addressing the issues raised, particularly regarding the precise definition of the treatment
