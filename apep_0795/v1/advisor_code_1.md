# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-23T12:06:51.115240

---

**Idea Fidelity**

The paper closely pursues the manifest’s original idea. It leverages the MLP linked-census data to study occupational sorting around the 1935 Social Security exclusion, implements the promised difference-in-differences/triple-differences comparisons, and explicitly focuses on Black versus white workers in excluded occupations (agricultural and domestic). The paper also explores the suggested mechanisms—domestic workers’ response, SEI gains, manufacturing entry, and geographic mobility—matching the manifest’s emphasis. One minor omission is a fuller discussion of the proposed county-level exposure IV (it is mentioned in the manifest but not implemented in the paper), but this does not undermine the overall fidelity to the stated research question and strategy.

**Summary**

This paper documents that Black domestic workers, after the 1935 Social Security exclusion of agricultural and domestic labor, switched into covered occupations at substantially higher rates than white domestic workers, while agricultural workers showed no such race-differential response. Using linked census data in a DiD/DDD framework, the authors argue that the differential reflects an “insured escape” incentive that operated where switching costs were low, producing measurable socioeconomic upgrading and increased entry into manufacturing. The paper contributes a behavioral dimension to the racial history of Social Security and to broader discussions of benefit-driven labor-market mobility.

**Essential Points**

1. **Parallel Trend Assumption Needs Stronger Evidence.** The DiD design relies critically on the assumption that the race-specific occupation-switching gap would have evolved similarly between 1920–1930 and 1930–1940 absent SSA. Apart from invoking the pre-SSA period, the paper provides no formal test of this assumption. Given known racial differences in mobility and the onset of the Depression, it is imperative to demonstrate that the Black–white gap in switching rates was stable (or trending similarly) in the pre-period—for example, by comparing 1910–1920 or 1900–1910 transitions if linkable, or by exploiting within-calendar-year age cohorts to show no pre-SSA divergence. Without this, the DiD estimate risks conflating SSA effects with other race-specific shocks or trends.

2. **Depression-Related Confounding Requires Additional Controls.** The Great Depression hit states and sectors unevenly, and Black and white workers may have been differentially exposed conditional on their occupation. The paper needs to show that results are robust to accounting for state–decade economic shocks (e.g., state-level unemployment, farm income, or cotton prices), or at least to including state × decade fixed effects and/or occupation × decade trends. Column (4) of Table 1 claims to include state × decade FE but reports only state FE; the specification that grudgingly allows for differential decline is thus unclear. Without absorbing these macro shocks, the observed race difference may capture, for instance, a sharper decline in white domestic mobility driven by demand contractions rather than SSA incentives.

3. **Selection and Linkage Concerns Should Be More Directly Addressed.** The idea that linkage quality depends on occupational stability raises the possibility that Black domestic workers who changed occupations are overrepresented in the linked sample (if occupation change correlates with successful linking). The paper notes this but offers no quantitative check. A robustness exercise that compares linking rates by race and occupation, or that uses a subset of workers with higher match quality (e.g., with unique names or multiple matching identifiers), would help allay concerns that the differential switching rate is partly mechanical.

If these issues cannot be addressed convincingly, the paper risks overstating the causal interpretation and should not proceed.

**Suggestions**

1. **Pre-Trend and Event-Study Evidence.** While decennial data limit finer event studies, you can still exploit the 1900, 1910, and 1920 censuses (many MLP linkages exist across earlier decades) to construct earlier decade transitions. Even if linkage quality deteriorates, a comparison of the Black–white, excluded-occupation switching gap in 1900–1910 and 1910–1920 would help establish whether the pre-treatment trend is stable. Alternatively, consider cohort-based placebo tests—e.g., focus on workers aged 35+ in 1930 whose occupational decisions in the 1920s would be fully observed and unaffected by SSA—to show no anomalous race-specific movements pre-1935.

2. **Flexible Timing Controls and Macro Shocks.** Column (4) of Table 1 is supposed to include state × decade fixed effects but shows only state FE; please clarify and, if not already implemented, estimate specifications with fully saturated state × decade effects so that the DD estimator relies only on within-state, cross-race differences. Second, augment the model with controls for local economic conditions (state/county unemployment, farm income per capita, cotton prices, New Deal program intensity) interacted with occupation type. This will show whether the domestic-worker result survives after accounting for differential demand shocks that could alternatively explain the racial pattern.

3. **Linkage Selection and Attrition.** The paper should provide summary statistics about linkage rates by race/occupation or, if those are unavailable, demonstrate robustness by weighting the analysis by a linkage-probability proxy (e.g., name frequency, out-migration). You could also limit the sample to individuals with identifiers suggesting high-quality linkage (e.g., presence of both parents’ names, less common surnames) to verify that the domestic-worker effect persists in a subset unaffected by differential attrition.

4. **Heterogeneous Effects Beyond Occupation Type.** The domestic-worker result is striking; to further support the mechanism, consider exploring whether the effect varies by urban/rural residence, age cohort, or gender. For example, if younger Black domestic workers—who had longer pension horizons—responded more strongly, this would bolster the “forward-looking incentive” narrative. Similarly, a larger effect in northern cities (beyond simple South/non-South split) would reinforce the switching-cost story.

5. **Clarify Sample Construction and Measurement.** The summary statistics table notes 1920-based sample, but the regression stacks transitions from 1920–1930 and 1930–1940. Spell out how attrition between censuses affects the sample and whether those lost to linkage differ systematically by race/occupation; report how many individuals contribute to each transition and how “switching” is measured (e.g., is a missing occupation in 1940 treated as non-switch?). Including a flow diagram would help readers assess whether sample composition changed dramatically between decades.

6. **Add IV or Alternative Identification.** The manifest mentioned using county-level exposure as an instrument to provide additional variation. Even if not fully implemented, consider adding an IV-style specification (e.g., using the 1930 county share of excluded occupations interacted with a post dummy) to isolate geographic exposure from individual-level selection. This would help show that the documented sorting is driven by regional differences in the coverage gap rather than unobserved individual characteristics.

7. **Discuss Alternative Mechanisms More Fully.** The “insured escape” interpretation rests on SSA coverage incentives, but other contemporaneous factors (e.g., New Deal welfare programs, migration networks, union organizing) also affected domestic workers. Expand the discussion of how these alternative channels might confound the identified effect and whether they can be ruled out (for example, show that the effect is not concentrated in areas with heavy NRA or WPA presence). This contextualization will strengthen confidence that SSA exclusion, specifically, drove the domestic-worker differential.

8. **Supplement with Descriptive Evidence.** Anecdotal or qualitative evidence (e.g., newspaper ads, WPA reports) describing how domestic workers perceived covered-sector jobs would enliven the mechanism argument. Even a short appendix excerpting such sources could reassure readers that the occupational choices were plausibly influenced by knowledge of Social Security coverage.

9. **Standard Errors and Clustering.** State-level clustering may be coarse given the number of states; consider two-way clustering (state × race) or wild bootstrap methods to account for possible few-cluster issues, especially since the key comparison combines race and time. Report whether the results change when clustering at the county level or by state × decade.

10. **SEI Gain Interpretation.** While a 4.8-point SEI gain among domestic workers is compelling, it would be helpful to translate that into more concrete occupational moves (e.g., proportion moving into manufacturing, clerical jobs). This can address concerns that the SEI movement reflects changes within domestic service rather than genuine upward mobility.

Overall, the paper addresses an important and understudied question with rich new data, but the causal story would be strengthened by deeper validation of the identifying assumptions, further robustness, and richer discussion of alternate explanations and mechanisms.
