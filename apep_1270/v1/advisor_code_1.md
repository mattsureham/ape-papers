# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-04-01T17:32:36.008200

---

**Idea Fidelity**

The paper closely follows the original idea manifest. It centers on the Swiss CO$_2$ levy, exploits the six discrete rate increases, and uses cross-cantonal heterogeneity in baseline oil-heating shares to construct a continuous treatment intensity. The focus on whether the levy induced technology switching—especially toward heat pumps versus intermediate fossil alternatives—matches the research question. All key data sources (BFS heating shares, levy schedule) and the generalized DiD identification strategy appear in the manuscript. One minor deviation: the manifest mentioned complementary municipal-level analysis (Thurgau) and Buildings Programme data, but the submitted paper focuses purely on canton-level GWS data; if those richer datasets were available, the paper would become more convincing. Nonetheless, the core identification and question are preserved.

**Summary**

The paper exploits Switzerland’s multi-step federal CO$_2$ levy on heating fuels together with pre-levy cantonal oil-heating shares to estimate how exposure to the tax affected the composition of residential heating systems between 2000 and 2024. The key finding is that higher levy exposure accelerated switching to gas rather than heat pumps, implying a “gas bridge” that carbon pricing alone could not overcome. Robustness checks (placebos, leave-one-out, long differences) support the claim that the levy triggered fossil-to-fossil substitution.

**Essential Points**

1. **Validity of the parallel-trends assumption and role of time variation.** The paper relies on a TWFE setup with canton and year fixed effects but only five observation years (2000, 2021–2024). The treatment variable is oil-share$_{2000}\times$levy$_t$, so identification hinges on the time variation coming solely from the levy increases after 2008. However, the first post-levy observations start more than a decade after the first rate change, and there is no panel data between 2000 and 2021 to observe the evolution in response to the earlier increases. This gap exacerbates concerns that the timing of gas adoption might correlate with trends unrelated to the levy (e.g., infrastructure expansion, energy efficiency programs) that also differ by oil share. Please provide stronger justification that differential pre-trends are not driving the results, for example by reconstructing intermediate years (2010, 2014, etc.) or, minimally, by comparing cantons’ evolution in other outcomes that should not respond to the levy (e.g., district heating shares) before 2008 to demonstrate parallelism.

2. **Treatment definition conflates level and intensity effects.** The treatment variable multiplies a fixed oil share (from 2000) by the current levy rate. Cantons with higher oil shares therefore have larger treatment values even in years when the levy is low, implying those cantons are “treated” even before the levy is binding. This could capture time-invariant differences rather than genuine differential responses to levy increases. The inclusion of canton fixed effects helps, but the interaction still makes cantons with high oil shares more responsive to any time effect, not just the levy. Consider re-specifying the model using the change in levy rate (∆Levy) or a post-2014 indicator to isolate the effect of rate increases, or by interacting oil share with discrete rate-change dummies. Confirm that the results persist when treatment is defined as oil share × (levy rate – baseline rate) or similar.

3. **Omitted mechanism controls and potential confounders.** The paper interprets the results as a tax-induced marginal switching to gas because installing a gas system is cheaper. However, the federal Buildings Programme redistributes levy revenue into reno subsidies, and cantons that initially relied more on oil also raise more revenue (tied mechanically to oil volumes). Those cantons may have expanded renovation subsidies or other programs that favor gas (e.g., infrastructure expansion, gas provider incentives). The current specification cannot disentangle the price signal versus subsidy channel. Please document and control for canton-level variation in Buildings Programme disbursements (or at least total levy revenue per canton) or in gas infrastructure expansion during the study period. Alternatively, explicitly discuss how these additional channels might bias the coefficient and whether the inference about the CO$_2$ levy as the causal driver still holds.

**Suggestions**

- Expand the temporal coverage if data allow. The analysis would benefit greatly from including intermediate years of the GWS series (e.g., 2010, 2015) to capture responses to the earlier levy rate increases. If yearly share data are not publicly available, consider interpolating from census snapshots or using other administrative sources (e.g., energy statistics) to construct a more continuous panel. This would strengthen the DiD design and allow event-study-style checks for pre-trends.

- Complement the canton-level analysis with the additional micro datasets mentioned in the manifest—especially the Thurgau municipality data and Buildings Programme subsidy flows. A within-canton analysis with more granular spatial variation could address lingering concerns about unobserved canton-level confounders and provide more evidence on whether gas adoption occurred in tandem with increased renovation subsidies. Even if only presented in an appendix, such robustness would reinforce the main interpretation.

- Provide visual evidence. Plotting the evolution of gas and heat pump shares over time separately for high- and low-oil-share cantons would illustrate the dynamics and allow readers to assess parallel trends visually. Similarly, a figure showing the treatment intensity distribution and its correlation with gas share changes would aid intuition.

- Clarify the economic magnitude. The statement that the mean treatment-level effect implies a 24 percentage point increase in gas share seems large relative to the observed increase (14% to 20%). A back-of-the-envelope calculation translating the regression coefficient into elasticities or percentage-point changes for a “typical” canton would help assess realism. It might also reveal that the coefficient captures long-term equilibrium differences rather than short-run responses.

- Address potential compositional issues. The GWS shares sum to 100% but may change because of new construction, demolitions, or heating system “mixed” installations. Discuss whether the share data capture replacement at the intensive margin (same dwellings switching) versus extensive margin (different cohorts of buildings). If possible, re-weight by dwelling counts or population to ensure the share changes reflect replacements rather than structural shifts in housing stock.

- Explore heterogeneous effects by gas infrastructure availability. The mechanism suggests that cantons with extensive existing gas networks should exhibit larger gas switching. Including an interaction with pre-existing gas share (or a proxy for infrastructure) would test this and strengthen the story. If the effect is concentrated where gas is abundant, it supports the “path dependence” narrative.

- Discuss implications for levy design. Since the levy applies equally to oil and gas, the carbon intensity differential makes gas cheaper per unit of heat. Consider calculating implicit carbon prices (per kWh or per GJ) to show how the levy might still make gas more attractive than heat pumps. This could feed into policy recommendations, such as differentiated levies or targeted subsidies to heat pumps, to avoid the gas bridge.

- Elaborate on the null heat pump result. The p-value of 0.056 for the recent period is suggestive but not definitive. Provide power calculations or confidence intervals to show whether the study is underpowered for that outcome. If possible, pool data across province-year observations or use a more aggregated outcome (e.g., new heat pump installations per capita) to improve precision.

- Improve the treatment of placebo results: the omission of the placebo table results in not showing whether the estimated coefficients are statistically different from zero. Include the coefficients and standard errors explicitly, and if possible, test whether gas/heating effects are statistically different from the placebo outcomes to reinforce the specificity of the levy channel.

- Finally, consider how future levy increases beyond CHF 120 might alter incentives. Does the gas bridge persist if the levy continues rising, especially if combined with electricity price changes (e.g., due to the CO$_2$ levy on electricity production)? Addressing this would help policymakers understand the dynamic implications of the findings.

Overall, the paper tackles an important question and produces intriguing results, but strengthening the identification strategy, expanding the empirical scope, and fleshing out the mechanisms would substantially improve the credibility and contribution.
