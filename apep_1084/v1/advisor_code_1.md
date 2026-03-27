# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-27T16:32:40.415597

---

**Idea Fidelity**

The paper stays very close to the idea manifest. It uses the January 2017 Gainful Employment score publication as the first shock, the June 2017 enforcement pause and eventual rescission as the rollback, and links those shocks to program-level IPEDS completions via the GE CIP × institution identifiers. The key empirical strategy—comparing “fail” versus “pass” programs within for-profit institutions, decomposing the post-publication period and the post-rollback period, and exploring racial compositional effects—is all present. The manuscript could make even clearer that the unit of observation is the program (CIP × institution) and remind the reader at each stage that the D/E scores were determined from earnings cohorts that precede the enrollment years used in the analysis, but overall it faithfully implements the manifest’s plan.

---

**Summary**

The author exploits the Gainful Employment publication and rollback sequence to argue that the public “scarlet score” stigma outlasts the regulatory threat. Using a panel of roughly 3,400 for-profit programs matched between the GE D/E data and IPEDS completions, the paper estimates that failing programs experienced persistent declines in completions that deepened after the Trump administration paused enforcement. The persistence of the effect, coupled with disproportionate losses for minority (especially Black) students, is interpreted as evidence that the information disclosure itself created an irreversible reputational regulation.

---

**Essential Points**

1. **Identification around the rollback is underdeveloped.** The key claim is that any additional decline after mid-2017 must reflect reputational damage because regulatory sanctions ceased. Yet the paper does not convincingly establish that the timing of the rollback is exogenous at the program level, nor that the signal of “no more sanctions” was crisply communicated in a way students recognized. In the two-stage specification, the post-rollout period is defined simply as 2018 onwards. That period coincides with other industry-wide shocks (continued scrutiny of for-profit colleges, some large closures, and macroeconomic trends) and it is not obvious why those shocks would affect failing programs differently from passing programs absent the rollback. The authors need to show that nothing else changed qualitatively for failing programs at the rollover point—ideally by comparing the evolution of similar programs at non-profit institutions or by exploiting alternative variation in media coverage of the publication versus the rollback. Without such checks, the attribution of the deepening decline to reputational persistence is speculative.

2. **Baseline differences between failing and passing programs raise concerns.** Failing programs are smaller, likely target different fields, and may be on inherently weaker trajectories even before the publication. The parallel trends assumption is critical, yet the only evidence provided is a mention of pre-treatment coefficients (without graphical support) and the usual fixed effects. It would be helpful to see the event-study graph with confidence intervals, plus robustness checks that condition on pre-treatment enrollment trends, program size, or field of study. In particular, restricting the sample to a tighter bandwidth around the 12% D/E cutoff (or using the continuous D/E score in an RDD framework) would address concerns that the comparison mixes fundamentally different programs. Absent that, the estimated “scarlet score” may partly reflect regression to the mean or other program-specific dynamics.

3. **Attrition and closure may bias the estimates, especially post-rollback.** The paper briefly notes that within-program closure is addressed via extensive margin regressions and dropping institutions that closed, but the main specification still conditions on surviving programs. If failing programs were more likely to exit, the post-rollback decline could simply reflect differential attrition rather than additional reputational harm. The 123 institutions with both fail and pass programs are only a subset of the sample; how representative are they after 2017? Showing Kaplan–Meier survival curves or estimating treatment effects on program closure using a discrete-time hazard model would clarify whether attrition is driving the result or whether the reputational effect persists even among programs that continue operating.

---

**Suggestions**

- **Provide a clear event-study figure and estimates.** The text alludes to pre-trends being “clean” and post-treatment gaps widening, but readers would benefit from seeing the event-study plot of the $\delta_k$ coefficients with confidence intervals. This would allow assessment of the parallel trends assumption and the timing of the divergence. Plotting the gap separately for total completions and minority completions would also illuminate whether the racial composition effects emerge with a lag, as claimed.

- **Leverage the continuous D/E score near the threshold.** The manifest mentions the opportunity for a regression discontinuity design around the 12% failure cutoff. Even a quasi-RD (e.g., local linear regression using the D/E score as the running variable) could complement the DiD estimates and show that programs just above the fail threshold diverged more than those just below. Such an exercise would strengthen the causal claim because it relies less on grouping programs by inherently different characteristics. It would also allow the authors to test whether there is a smoothly varying relationship between continuous D/E and the post-rollout slope, which would support the reputational scar interpretation.

- **Clarify the rollback’s timing and implementation for prospective students.** The argument hinges on students realizing that regulatory sanctions had been paused. To make this plausible, include evidence from contemporaneous press releases, enrollment guidance, or media coverage indicating that students were aware that the failing programs were no longer at risk of losing funding. If such evidence is unavailable, consider instrumenting the rollback effect with the publication of DeVos’s announcement (June 2017) rather than simply using calendar years. Alternatively, show that programs with similar reputational shocks but different exposure to the official announcement (e.g., those with more media attention) exhibit differential trends once sanctions were paused.

- **Expand the within-institution results.** The within-institution specification is a strength, but the manuscript currently reports only the aggregate effect. Present the same two-stage decomposition for the within-institution sample (including event study) and discuss whether the within-school estimates show the same post-rollback deepening. This would reassure readers that the findings are not driven by institution-level shocks or the changing composition of institutions over time.

- **Address standard error concerns and statistical power.** With only 123 institutions in the within-institution sample and 404 failing programs, standard errors can be large. Consider reporting wild-cluster bootstrap confidence intervals or randomization inference to show that the large magnitudes are not artifacts of imprecision. Additionally, mention the number of clusters used in the main regressions and how the results change (if at all) when clustering at the program or even CIP × state level.

- **Explore alternative mechanisms for racial disparities.** The paper posits that the post-rollback decline disproportionately affected minority students because they rely more on for-profit pathways. To support this, consider incorporating controls for the racial composition of the overall program cohorts (if available) or analyzing whether passing programs with high minority shares absorbed the displaced students. Another angle is to examine whether programs serving majority-minority students were more likely to linger in the zone or fail completely, which could exacerbate the observed decline.

- **Discuss general equilibrium effects and policy implications with nuance.** While the conclusion draws a compelling narrative about the irreversibility of disclosure, it would help to acknowledge that some students might have shifted to better programs (e.g., community colleges or public institutions) as a matter of policy success. Including some information, even qualitative, about whether completion declines at failing program were offset by increases elsewhere would help frame the welfare implications. If data limitations prevent this, state explicitly that the analysis is silent about downstream student outcomes once they leave the failing programs.

- **Document data processing steps in an appendix.** Given the multistep merge between the GE publication, IPEDS completions, and institutional metadata, outline the matching procedure, any data cleaning (e.g., handling of missing CIP codes), and the construction of the minority and Black completion variables. This increases reproducibility and lets readers assess whether measurement error might attenuate the estimates.

Implementing these suggestions would substantially strengthen the confidence in the causal interpretation and sharpen the policy takeaways.
