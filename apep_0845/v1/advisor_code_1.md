# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-24T15:34:18.629064

---

**Idea Fidelity**

The manuscript faithfully tracks the manifest’s ambition. It studies the 2013 Professional Qualifications Directive reform, uses the Eurostat lfsa_eoqgan overqualification gap as the main outcome, and models treatment intensity through pre-reform counts of regulated professions. The proposed identification strategy (continuous DiD with country and year fixed effects, event study diagnostics, placebo with non-EU migrants, and robustness checks such as wild cluster bootstrap and randomization inference) is implemented. All key elements—variation in regulated professions, temporal scope centered on the 2016 transposition deadline, and the research question of whether administrative streamlining moved mobile professionals—are present.

---

**Summary**

The authors examine whether Directive 2013/55/EU, which modernized the EU Professional Qualifications regime, reduced overqualification among foreign professionals by exploiting cross-country variation in the number of regulated professions as a continuous treatment. Using Eurostat LFS data for 24 EU countries (2006–2023), they find no evidence that higher-intensity countries experienced larger declines in the overqualification gap after the reform; similar null effects for non-EU migrants suggest that broader integration trends, not the directive, explain the evolution. The paper highlights that administrative reform alone may be insufficient to foster professional mobility when deeper cultural and informational frictions persist.

---

**Essential Points**

1. **Parallel Trends and Continuous Treatment Validity:** The event study shows sizeable pre-treatment fluctuations (e.g., statistically different coefficients at \(t=-4\)) and overall noisiness, casting doubt on the key parallel-trends assumption when treatment is measured continuously by the count of regulated professions. High-regulation countries may already have been trending differently in the overqualification gap due to unobserved factors (e.g., labor market rigidities or macroeconomic shocks). You need to more convincingly rule out differential pre-trends—e.g., by demonstrating similar trends conditional on relevant covariates, adding country-specific linear/quadratic trends, or using synthetic control-style weighting. Without that, it is hard to interpret the post-2016 coefficient as causal.

2. **Treatment Intensity Measurement and Exogeneity:** The pre-reform count of regulated professions is time invariant and likely endogenous to broader regulatory institutions that also affect overqualification. Countries with many regulated professions may simultaneously have more stringent labor market policies, greater reporting requirements, or different migrant populations, which could drive both the number of regulated professions and the overqualification gap trend. The paper requires stronger justification (perhaps via historical institutional reasons) that the pre-2016 regulated-profession count is exogenous to post-reform dynamics, or it should seek alternative sources of variation—such as actual timing of compliance, differential reliance on the European Professional Card, or share of professions falling under mutual recognition before the reform.

3. **Outcome Composition and Placebo Interpretation:** Comparing EU-foreign with non-EU overqualification gaps assumes that non-EU migrants are a valid control for broader trends, yet non-EU mobility is shaped by different economic and policy forces. Without addressing compositional shifts (e.g., a growing share of non-EU workers in specific occupations or countries), the placebo could be reflecting unrelated dynamics. Consider decomposing overqualification by occupation, sector, or migrant origin to ensure that the gaps are comparable, or alternatively, constructing an outcome that isolates only those professions directly targeted by the Directive (e.g., nurses/pharmacists) to sharpen the mechanism.

If additional critical issues arise beyond these three, the paper should be reconsidered—otherwise, it can proceed conditional on adequately addressing them.

---

**Suggestions**

1. **Strengthen Pre-Trend Evidence through Flexible Trends or Matching.** The event study evidence is a concern because coefficients before 2016 are non-zero and sometimes sizable. Consider augmenting the model with country-specific linear and quadratic trends to absorb long-term divergences; alternatively, employ a synthetic control or matching approach to ensure that high- and low-regulation countries display parallel behavior before 2016. If feasible, pre-register a falsification test using a pseudo-reform year to see whether the estimated effect disappears when the treatment “starts” earlier. Displaying smoothed averages of the overqualification gap by regulatory intensity bin over time would also help readers visually inspect the trends.

2. **Explore Alternative or Additional Measures of Treatment Intensity.** The raw count of regulated professions is a blunt proxy for the magnitude of administrative reform. You could enrich the analysis by:
   - Weighting each country’s count by the share of recognition applications attributable to each profession (if administrative data are available), thus capturing how many people actually go through the procedure.
   - Distinguishing professions directly affected by the European Professional Card (nurses, pharmacists, physiotherapists) from the rest: use those professions as targeted subgroups and test whether mobility/outcomes of professionals in those fields responded differently.
   - Using the extent of electronic IMI participation or the number of infringement proceedings (as a measure of compliance effort) as supplementary treatment measures. This would help verify whether treatment intensity relates to procedural changes rather than being an artifact of historical regulation.

3. **Unpack the Outcome and Migration Composition.** Aggregate overqualification gaps may mask compositional changes across citizenship groups or around the reform. Consider:
   - Running the analysis for narrower groups (e.g., EU-foreign workers in regulated professions only) or by gender and education level to see whether any subgroup reacts to the reform.
   - Controlling for destination-country changes in the stock of migrant professionals (Eurostat provides migration inflows by citizenship), since a growing EU migrant population might reduce overqualification through network effects irrespective of the Directive.
   - Including country-year controls for macroeconomic shocks (GDP growth, unemployment) and changes in tertiary attainment to capture time-varying factors affecting overqualification. Although you cite limited data, Eurostat or OECD databases can supply such controls.

4. **Clarify Mechanism and Interpretation of the Null.** The conclusion that cultural frictions dominate is plausible but feels speculative without direct evidence. To bridge the gap:
   - Present descriptive evidence showing that the reform substantially reduced administrative hurdles (e.g., faster processing times, higher EPC issuance) and yet professional mobility did not adjust. If such data are unavailable, discuss more explicitly why a null finding should be interpreted as “recognition reform powerless” rather than “treatment was too weak or poorly implemented.”
   - Alternatively, use the non-EU placebo to check whether the Directive’s institutions (IMI, EPC) had measurable usage increases in high-regulation countries; demonstrating that these procedures were, in fact, adopted would lend credibility to the idea that administrative reform was deployed but still ineffective.

5. **Improve Power Discussion and Effect Size Interpretation.** The power calculation is helpful but could be more precise. Given the standardized treatment, translate the minimum detectable effect into real-world units (percentage-point change in the overqualification gap for, say, a move from the 25th to 75th percentile of regulated professions). This would clarify whether the estimated null is substantively meaningful or simply due to lack of variation. Also, discuss how large an effect would be required to justify the policy (e.g., closing half the gap) and whether such effect sizes are plausible relative to prior licensing studies.

6. **Consider Heterogeneity by Migration Intensity.** Countries with large flows of EU professionals may be more sensitive to recognition reforms. Explore whether the treatment effect varies with the stock or inflow of EU migrants pre-reform. If data permit, interact regulatory intensity with measures of net migration of EU professionals to see whether reforms matter more where demand is higher. This could also explain why some countries show slight increases in the gap: perhaps those countries attracted different migrant cohorts post-reform.

7. **Strengthen Reporting of Inference and Robustness.** Some robustness checks (e.g., leave-one-country-out range) suggest point estimates vary substantially. Provide a plot of leave-one-out estimates to assess sensitivity. Similarly, it would be useful to show how the event-study coefficients change when you include country-specific trends or pre-trend adjustments, helping readers gauge the fragility of the parallel-trends assumption. Given the small number of clusters, clarify whether wild cluster bootstrap p-values are two-sided and how they relate to the null hypothesis.

8. **Expand Discussion on Policy Implications and Future Work.** The recognition illusion metaphor is appealing. Flesh out the conclusion by linking back to specific EU institutions (e.g., are language and informational barriers being addressed in EU programs?). Suggest concrete next steps, such as linking LFS data with administrative records or conducting surveys of regulatory authorities to understand why certain professions remain regulated. This would help policymakers see how your findings guide future integration efforts.

Implementing these suggestions would bolster the paper’s credibility and deepen its contribution to the literature on labor mobility and occupational regulation.
