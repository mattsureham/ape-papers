# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-25T20:41:26.377202

---

**Idea Fidelity**

The paper largely adheres to the manifest. It exploits the staggered adoption of cantonal tobacco billboard bans between 1997 and 2017, relies on the FOPH OKP administrative healthcare expenditure dashboard, and estimates fiscal consequences via a staggered difference-in-differences framework (Callaway and Sant’Anna) with the 10 never-treated cantons serving as controls. The analysis includes the pre/post event study, placebo categories, leave-one-out checks, and references to Stoller (2026) for treatment dating. The only minor divergence is the omission of any explicit control for cantonal smoking prevalence through time, even though the manifest flagged it as a control variable; incorporating such controls would help tie the ban-to-cost channel explicitly to tobacco use behavior.

**Summary**

The paper provides the first causal estimate of how tobacco billboard advertising bans affect per-capita mandatory health insurance costs in Switzerland. Using a CS-DiD design with never-treated cantons as controls, it estimates a 5.4 percent reduction in total healthcare costs, driven by hospital inpatient/outpatient spending, with larger effects over time and no significant movement in ostensibly smoking-unrelated categories. The findings underscore that the fiscal benefits of advertising regulation grow over the medium run and mainly stem from avoided severe smoking-related illnesses.

**Essential Points**

1. **Treatment Timing and Confounding Policies:** Cantonal governments that introduce billboard bans may simultaneously adopt other tobacco control or health policies (smoke-free laws, price subsidies, cessation programs) or differ systematically in unobserved trends (urbanization, insurance reform). The paper acknowledges this but does not meaningfully address it empirically. Without controlling for other major policy changes or time-varying canton characteristics, it is difficult to isolate the effect of the billboard ban per se. The authors should document the timing of other significant tobacco/health interventions and either control for them explicitly or demonstrate that their adoption is not correlated with the ban. If data on other policies are unavailable, a bounding exercise (e.g., Oster-style) or synthetic control comparison for selected cantons could help.

2. **Empirical Link to Smoking Behavior:** The identification hinges on the assumption that billboard bans reduce healthcare costs through lower smoking prevalence, yet no smoking-prevalence outcome is included in the empirical work (beyond referencing Stoller). Presenting contemporaneous smoking prevalence or cessation-rate data would (a) validate that bans affect smoking behavior in these cantons and (b) allow for mediation analyses (e.g., a two-stage approach) that tie cost reductions to smoking declines. Without this, the channel remains theoretical.

3. **Inference and Magnitude of Placebo Effects:** The wild-cluster bootstrap p-value of 0.16 and sizeable variance in placebo categories (physiotherapy and SPITEX) suggest limited statistical power and potential residual confounding. In particular, the placebo categories show point estimates comparable to the main effect, which undermines confidence in the specificity of the mechanism. The authors need to either increase precision (e.g., using stacked or aggregated data, Bayesian shrinkage) or strengthen the falsification by showing that placebo estimates are statistically indistinguishable from zero even accounting for multiple testing. If data constraints limit inference, the paper should be explicit about the suggestive nature of the results.

**Suggestions**

1. **Incorporate Time-Varying Confounders:** Supplement the CS-DiD specification with time-varying canton-level covariates—particularly smoking prevalence, average income, urbanization, demographic composition (age structure), healthcare supply shocks (hospital beds per capita), and other tobacco-control policies—to absorb residual trends. If detailed data on covariates are unavailable every year, proxying with interpolated series or incorporating canton-specific trends (or even event-time dummies interacted with pre-trends) will help ensure that comparisons are not driven by differential secular dynamics.

2. **Strengthen the Channel via Smoking Data:** Given the manifest’s goal of linking advertising bans to healthcare costs, the paper would be considerably stronger if it documented the effect on smoking prevalence or consumption using the same policy variation. If full cantonal smoking series are unavailable, the authors could use adult smoking prevalence (perhaps intermittently reported) or aggregate cessation statistics; even better, they could show that canton-level cigarette tax revenues or tobacco sales decline after bans. A mediation analysis could then quantify how much of the cost reduction corresponds to measurable smoking declines.

3. **Enhance Placebo Strategy:** The current placebo categories produce mixed signals (e.g., physiotherapy and SPITEX negative effects). Consider refining placebo choices to categories that share the payment structure of smoking-related care but are unaffected in theory—e.g., pediatric vaccinations or dental preventive services. Alternatively, conduct permutation tests or generate placebo treatments (assigning false ban years to never-treated cantons) to show that the estimated effect is not an artifact of the estimator. The placebo categories should span the same data-generating process to rule out data quirks.

4. **Report Effect in Levels Adjusted for Time:** The main log estimate is interpretable as percentage changes, but the level effect of CHF 79 per capita per year begs the question of its fiscal magnitude over time. A back-of-the-envelope decomposition (number of insured × effect × years) would make the fiscal implications more tangible and would help policy audiences weigh the trade-off between upfront regulatory costs and long-term savings. Additionally, since costs rise over time due to medical inflation, presenting effects relative to a trend (e.g., as deviations from canton-specific pre-trends) could show whether the ban merely slows growth versus reduces levels.

5. **Address Early-Adopter Composition:** Early adopters appear to be more urban and higher-spending than late adopters. It would help to control for time-invariant characteristics (beyond canton FE) by interacting pre-ban characteristics with time or by conducting a synthetic control for a subset of early adopters using never-treated cantons as donors. This would demonstrate that the gradient between early and late adopters is not simply picking up selection into adoption timing.

6. **Clarify Standard Error Reporting:** The paper reports clustered standard errors but simultaneously notes that cluster inference is weak. It would be helpful to present both clustered SEs and wild cluster bootstrap confidence intervals for all main specifications (not just TWFE). If wild bootstrap is not feasible for all tables, at least include a supplementary table with bootstrap-based intervals for key outcomes. This transparency will help readers gauge which findings are robust to finite-sample inference.

7. **Expand the Discussion on External Validity:** The Swiss context features universal insurance, cantonal autonomy, and billboard-specific bans. To guide readers in other settings, discuss how differences (e.g., centralized healthcare systems, comprehensive advertising bans) might amplify or attenuate the observed fiscal effects. Does the paper expect larger effects in systems with higher smoking prevalence or less rigid hospital pricing?

8. **Make the Data Code Available:** The manifest indicates data access from the OKP dashboard. Including either the cleaned dataset or the replication code (perhaps in an online appendix) would facilitate transparency and future replication. Even if the raw data cannot be shared, describing the transformation steps in more detail (e.g., log transformation, treatment coding) would help readers assess the empirical strategy.

By addressing these points, the authors can fortify the causal arguments, clarify the mechanism linking bans to costs, and increase confidence that the estimated fiscal dividend genuinely arises from tobacco advertising restrictions.
