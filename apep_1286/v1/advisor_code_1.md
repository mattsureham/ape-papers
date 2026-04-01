# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-04-02T00:35:21.850954

---

**Idea Fidelity**

The paper closely follows the manifest’s core proposal. It uses the within–Technology Center 3600 (TC 3600) art-unit variation in \S101 rejection intensity around *Alice* to identify heterogeneous eligibility enforcement, relies on BigQuery USPTO data with art-unit–quarter aggregation, and implements a continuous-treatment DiD. The paper touches on the heterogeneous impact on small entities via rejection/continuation outcomes only indirectly (through art-unit rejection rates) rather than directly estimating abandonment or entity-level exit, so it would be helpful to explain that omission or integrate it more explicitly. Aside from that, all major elements of the original identification plan—parallel trends checks, placebo outcome, cross-TC robustness—are present.

---

**Summary**

This paper exploits the within–Technology Center 3600 heterogeneity in \S101 rejection rates following the *Alice* decision to study how judicial eligibility doctrine reshaped patent prosecution. Using art-unit treatment intensity defined as the pre/post *Alice* change in \S101 rejections, the author estimates continuous-treatment DiD models with art-unit and quarter fixed effects and finds large, immediate, and persistent eligibility shocks in high-exposure units, a negative placebo on \S103 rejections, and corroborating cross–technology-center comparisons.

---

**Essential Points**

1. **Endogeneity of the Treatment Measure.** The “Alice shock” is defined as the post/pre change in \S101 rejection rates. This uses post-treatment outcomes to construct the treatment intensity, creating a mechanical relationship between the treatment and the outcome and violating the standard DiD setup where treatment status should be predetermined. This can exaggerate the effect or even render the design tautological. The authors need to re-specify the treatment intensity using purely pre-*Alice* information—e.g., art-unit-level attributes or projections of exposure—or, at minimum, demonstrate that the treatment definition is exogenous (e.g., through first-stage valid instruments) and does not mechanically scale with the outcome. Without this, the causal interpretation of $\beta$ is compromised.

2. **Limited Variation and Inference Concerns.** With only 71 treated art units and quarter clustered errors, the reliance on standard DiD inference (even with art-unit fixed effects) is fragile, particularly given the high serial correlation and the continuous treatment. The paper should adopt recent approaches for inference with few clusters (e.g., wild bootstrap) or show that conclusions are not driven by a handful of high-shock units via more extensive leave-one-out or influence diagnostics. The reported specifications (e.g., Column 1 with 126 observations) suggest that the degrees of freedom are very limited, and clustering at the art-unit level may understate the true uncertainty.

3. **Mechanism for Applicant Behavior Remains Implicit.** The policy question is the recomposition of innovation via small-entity exit, but the paper currently focuses on examiner-level rejection intensity. To claim that “eligibility traps” push small entities out, the authors need to connect the art-unit rejection shock to applicant-level outcomes such as abandonment, withdrawal, or subsequent filings. At present the narrative jumps from \S101 intensity to applicant chilling without empirical support in the presented tables. Either provide additional analyses at the applicant/application level or tone down the policy claims.

---

**Suggestions**

1. **Redefine Treatment Intensity Using Pre-*Alice* Predictors.** Consider constructing the “Alice shock” from art-unit-level characteristics observable before 2014 (e.g., technological proximity to abstract ideas, historical rejection patterns, examiner profiles). Alternatively, define it as the post/pre change but instrument it with an exogenous proxy such as the share of applications classified in software-heavy subclasses prior to 2014. This would break the mechanical link between the treatment and the outcome and strengthen the causal claim.

2. **Report Event-Study With Confidence Bands.** The text references an event study, but no figure or table is provided. Plot the dynamic coefficients $\beta_k$ with 90/95% confidence intervals to transparently show the absence of pre-trends and the persistence of the post-*Alice* effect. That event study could also show how the treatment intensity matters in each post-period (e.g., interacting $AliceShock_a$ with year indicators) rather than relying solely on aggregate post vs. pre.

3. **Strengthen Robustness on Pre-Trends and Shock Stability.** The current parallel-trend argument rests on similar pre-*Alice* levels and a general statement about the event study. Provide more formal evidence: regress \S101 rates on time trends interacted with quantiles of the shock or run placebo DiD with fake treatment dates. Also, explore whether the shock is driven by a few cutting-edge art units by showing the distribution of Alice shock and re-running specifications after removing the highest and lowest deciles.

4. **Clarify the Placebo and Substitution Interpretation.** Column (2) presents a negative \S103 coefficient, interpreted as substitution. Since the treatment intensity equals the change in \S101 rates, it is mechanically related to \S101 outcomes and may mechanically relate to other rejection bases if examiners add multiple flags within the same action. Consider controlling for the total number of rejections or using the within-art-unit change in \S103 relative to other sections to make the substitution claim more precise.

5. **Connect to Applicant-Level Outcomes.** Even if the main focus is art-unit heterogeneity, the paper’s policy motivation revolves around small-entity exit. Using the same datasets, construct application-level outcomes such as abandonment probability or time-to-final-disposal and regress those on the art-unit treatment intensity. Show directly that high-exposure art units saw higher abandonment or fewer follow-on filings, which would substantiate the broader innovation policy claim.

6. **Provide More Transparency on Data Aggregation.** The Appendix notes 71 art units but earlier summary statistics table references 73. Clarify the sample selection, especially for the control TC 1600 art units. Also describe handling of missing data, zero office-action quarters, and how rejection flags are aggregated when a single office action has multiple rejection bases.

7. **Discern Between Examiner and Applicant Responses.** The paper emphasizes examiner-level adjustments to doctrine. To disentangle examiner decisions from applicant selection (e.g., applicants self-sorting into less strict art units), examine whether the composition of applications by applicant type or firm size changed within art units post-*Alice*. Running regressions of applicant attributes on the treatment might shed light on this selection mechanism.

8. **Reassess the Cross–Technology Center Comparison.** Column (4) compares TC 3600 to TC 1600, but the only covariate is a post indicator and a TC interaction, leaving open that other simultaneous shocks affected the two centers differently. Including additional controls (e.g., examiner staffing changes, application mix) or using a synthetic control approach might make this comparison more credible.

9. **Discuss External Validity Carefully.** The paper claims that eligibility doctrine creates “pockets of near-prohibition.” It would help to quantify the extent: e.g., plot the share of applications in high-shock art units and discuss whether these art units represent a narrow slice of overall innovation or a significant fraction of TC 3600 activity. This informs whether the “eligibility trap” is an isolated phenomenon or has broader implications.

10. **Consider Alternative Outcomes.** Beyond office-action rejection rates, outcomes such as allowance rates, prosecution length, or appellant activity might provide complementary insights into how *Alice* reshaped enforcement. If data permit, show whether high-shock art units saw a decline in allowance rates or an uptick in appeal filings.

By addressing these points, the paper would significantly strengthen its identification, inference, and policy relevance while keeping the empirical narrative cohesive.
