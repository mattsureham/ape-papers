# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-04-02T16:49:54.055160

---

**Idea Fidelity**

The paper largely adheres to the original idea manifest. It uses Census BPS county-level data, focuses on the staggered adoption of state single-family preemption policies, and emphasizes the missing middle share as the outcome. The identification strategy—staggered DiD with Callaway & Sant’Anna adjustments and randomization inference—is implemented. One deviation: the manifest mentioned five reform states (including Washington), but the paper treats only four states as treated (excluding Washington for no compliance yet), which is a defensible clarification rather than a substantive departure. The author also introduces the “implementation gap” narrative, which extends but remains consistent with the original research question about whether state preemption shifts construction toward missing middle housing.

**Summary**

The paper evaluates whether recent state-level preemption of single-family zoning increased the share of new construction in two-to-four-unit “missing middle” buildings using county-level Census BPS data from 2004–2024. A pooled staggered DiD estimate finds no average effect, but state-level heterogeneity reveals that Oregon’s HB 2001 substantially increased the missing middle share while California, Maine, and Montana did not. The divergence is interpreted through an “implementation gap”: legal authorization is insufficient absent prescriptive enforcement and local compliance mandates.

**Essential Points**

1. **Credibility of the Pooled Identification Benchmarks**: The pooled TWFE estimates hinge on parallel trends between treated and never-treated counties, yet the paper itself notes that the Callaway-Sant’Anna pre-test rejects parallel trends ($p = 0.007$) driven by Montana. While excluding Montana improves the $p$-value to 0.037, it remains marginal. This undermines the credibility of the pooled estimate, especially when Montana moves the aggregate estimate downwards. The paper must demonstrate more convincingly that the pooled comparison is valid—either by showing parallel pre-trends (perhaps with flexible controls, matching, or synthetic control checks) or by framing the pooled result more cautiously and emphasizing state-specific estimates. Without this, readers cannot be confident that the null pooled effect is not an artifact of pre-existing divergence.

2. **Interpretation of State Effects amid Potential Confounders**: Oregon’s positive effect is interpreted as evidence that “prescriptive” implementation works, while other states’ nulls are attributed to lax implementation. However, the four states differ on many dimensions (demand growth, permit-issuance capacity, housing markets, supply constraints). The paper needs to rule out alternative explanations—e.g., that Oregon was already experiencing rising multifamily construction due to population growth, or that California’s sheer scale and different local incentives mask an effect. Additional analysis (e.g., placebo tests using earlier years, within-state variation exploiting differential implementation timing, balance on pre-trend covariates) is necessary to ensure that the state estimates capture the causal effect of the reforms rather than confounding dynamics.

3. **Treatment Definition and Exposure Heterogeneity**: Assigning treatment at the county level solely via state compliance ignores within-state heterogeneity in actual policy exposure (e.g., not all counties include jurisdictions covered by compliance deadlines or high-demand areas). This is especially salient in California, where SB 9 primarily applies in urbanized areas and can be blocked by cities through objective standards. The paper should incorporate heterogeneity in exposure intensity—perhaps weighting counties by the share of population in cities with high SB 9 application rates, or by urbanization levels—and test whether “treated” counties that are more directly affected show stronger responses. Doing so would clarify whether the null results reflect implementation failure (as claimed) or misclassification of treatment intensity.

If addressing these essential points requires substantial additional work beyond modest revisions, consider rejection until identified validity concerns are resolved.

**Suggestions**

1. **Strengthen Pre-Trend Diagnostics**
   - Present the event-study coefficients graphically with confidence intervals to demonstrate the pre-treatment trajectory visually. Include separate graphs for the pooled sample and for each treated state, highlighting Montana’s divergence.
   - Consider augmenting the TWFE model with county-specific linear time trends or synthetic control weights to absorb pre-existing trends, and report whether the pooled estimate remains null.
   - Explore a “leave-one-state-out” analysis to show how sensitive the pooled estimate is to each treated state and whether Oregon’s positive trend is driving the aggregate.

2. **Deepen the Implementation Gap Mechanism**
   - The narrative would benefit from systematic evidence on implementation features. Compile a table summarizing deadlines, enforcement provisions, state oversight, and compliance assistance for each reform. Where possible, provide descriptive statistics on how many cities in each state adopted compliant codes by the deadline, or whether the state intervened (e.g., Oregon DLCD enforcement actions). 
   - If data allow, construct measures of local permitting friction (e.g., average permit processing times, discretionary review incidences) before and after each reform, to anchor the claim that California/Maine/Montana left these barriers intact while Oregon did not.
   - Consider interviewing or citing secondary evidence on SB 9 application rates, permit denials, or legal challenges to reinforce the implementation story.

3. **Refine Counterfactual and Control Groups**
   - The paper currently uses all never-treated counties as controls. To ensure comparability, try restricting the control group to states with similar pre-treatment missing middle shares and growth dynamics (propensity score matching on pre-treatment trends or geographic proximity). Present the pooled estimate under these alternative control sets to demonstrate robustness.
   - Since the reforms were implemented in rapidly growing western states, the pre-treatment economic and demographic context might differ from the national average. Control for time-varying state-level shocks (e.g., employment growth, mortgage rates, housing starts) to reduce omitted variable bias.

4. **Clarify the Role of Supply Constraints**
   - The discussion acknowledges that construction costs and interest rates can limit missing middle production even under favorable zoning. It would be helpful to quantify this effect empirically—e.g., interact treatment with local house price growth or construction cost indices to see whether the effect is concentrated where demand/cost conditions are less binding.
   - Alternatively, explore whether Oregon’s effect is larger in counties with weaker supply constraints (lower costs, higher vacancy). This can help disentangle whether the observed heterogeneity reflects implementation versus broader supply-side limits.

5. **Enhance the Placebo and Anticipation Analyses**
   - The paper mentions anticipation in Oregon but does not present specific event-study leads. Estimate the dynamic treatment effects up to three years before the reform, and report whether there is evidence of anticipation. If there is, adjust the treatment window accordingly.
   - Expand placebo testing beyond the placebo year exercise—e.g., conduct “fake treatment” exercises assigning treatment to similar states that did not reform, or to later years, to show that the estimator does not find effects when none should exist.

6. **Address Interpretation of Montana Estimate**
   - Montana’s negative effect raises more questions than it resolves. Investigate whether this is due to seasonal volatility, data irregularities (e.g., small counts causing noisy proportions), or other reforms coinciding with the preemption law. Provide a more detailed explanation (or drop Montana from pooled estimates if it is not a reliable treated unit).
   - Consider a heterogeneity check limited to Montana’s larger counties or those with more consistent permit reporting to test whether the negative estimate persists.

7. **Expand on Policy Implications**
   - The conclusion argues for “prescriptive” state intervention, but policymakers also care about feasibility and political economy. Discuss whether Oregon’s model is politically transferable to other states, considering legislative capacity, enforcement budgets, and local resistance.
   - If the missing middle remains bounded even with prescriptive interventions, what complementary policies (subsidies, incentives for affordable housing, off-site construction) would be necessary? This would situate the findings within broader housing policy debates.

8. **Technical Clarifications**
   - Provide more detail on the construction of the RI procedure—do the permutations respect the number of treated counties per state? Clarify how RI handles the fact that treatment occurs in cohorts (2022 and 2023).
   - In the robustness table, specify the dependent variable units (share in percentage points). This will help readers interpret the magnitude of the different point estimates.

9. **Data Transparency**
   - Share summary statistics or plots that illustrate the evolution of missing middle shares in each treated state compared to their control group (e.g., parallel trend plots). This visual evidence supports the identification claims.
   - If the paper is intended for AER: Insights, consider including a concise figure summarizing the main state-level estimates with confidence intervals to highlight heterogeneity.

By addressing these suggestions, the paper will provide a more compelling and transparent evaluation of state zoning preemption, enhance the credibility of both the null and heterogeneous findings, and clarify the practical lessons for housing policy.
