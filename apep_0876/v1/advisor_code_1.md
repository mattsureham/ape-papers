# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-24T21:44:02.617197

---

**Idea Fidelity**

The paper stays very close to the original manifest. It exploits IRS SOI state-to-state migration data across seven AGI brackets and focuses squarely on the SALT deduction cap (2018 TCJA) as the core tax shock, along with the broader motivation of reconciling Young-Varner and Kleven-Landais-Saez’s conflicting findings. The triple-difference design, the emphasis on the income gradient, and the decomposition into inflow and outflow channels all mirror the idea document. No major elements of the proposed identification, data sources, or research question appear to have been omitted.

---

**Summary**

The paper uses the IRS SOI migration files (2011–2021) to estimate how the 2018 SALT deduction cap affected interstate migration across seven income brackets. A triple-difference specification comparing high- versus middle-income filers, high- versus low-SALT states, and pre- versus post-2018 reveals a sharply increasing migration response with income, driven mostly by accelerated outflows. The results suggest that tax-induced migration is concentrated among the very top of the income distribution while being modest for lower brackets, thereby bridging previous conflicting findings on rich-person mobility.

---

**Essential Points**

1. **Parallel Trends / Dynamic Validation.** The credibility of the triple-difference hinges on the assumption that, absent the SALT cap, the income-gradient of migration would have evolved similarly in high-SALT and low-SALT states. Yet the paper presents no event-study or placebo showing that the high-income versus middle-income differential followed similar trends across these sets of states prior to 2018. Please include a proper parallel-trends exercise—ideally a dynamic specification or visual showing pre-treatment coefficients—to bolster causal claims.

2. **SALT Exposure Measure and High-Income Definition.** The main interaction uses a binary “HighSALT” indicator (≥\$13K average deduction) and a high-income bracket cutoff (≥\$100K). These cutoffs are substantively important but appear arbitrary. Provide sensitivity analyses with alternative thresholds, and consider using the continuous SALT deduction amount interacted with more granular measures of income exposure (perhaps percentile of bracket or actual deduction distributions) to demonstrate that results are not driven by a sharp classification rule.

3. **Confounding from Concurrent TCJA Provisions and Other Shocks.** 2018 featured multiple TCJA changes (national rate cuts, pass-through deduction, estate tax change) that could affect high-income filers’ migration decisions, as well as non-tax shocks (e.g., stock market, rising remote work before COVID). While the state×year and bracket×year fixed effects mitigate some concerns, migrants could respond to these other changes differently across income brackets. Please provide more direct evidence (e.g., placebo in states with low SALT exposure but similar other characteristics, or regressions controlling for state-level tax-rate changes and local housing-market shocks) that isolates the SALT-cap channel.

---

**Suggestions**

1. **Event Study for Triple-Difference.** Implement an event-study version of equation (1), interacting the high-SALT × high-income indicator with leads and lags of the post-2018 dummy. Plot the coefficients for each year to show that the differential migration response emerges only after 2018 and that pre-treatment trends are flat. This would greatly strengthen the identification story.

2. **Heterogeneous Effects Beyond Binary Cutoffs.** The income gradient is compelling, but you could deepen it by (a) estimating the triple interaction separately for each bracket (as you do for the SALT_z × post regressions) within the full specification and plotting the coefficients; (b) using the actual share of itemizers in each AGI bracket (available from SOI) to weight the treatment intensity; and (c) allowing the “high-income” category to vary (e.g., AGI ≥ \$150K, ≥ \$200K). This would clarify how steep the gradient is and whether there is a threshold or smooth increase.

3. **Explicit Control for Other State-Level Tax Changes.** Even with state×year fixed effects, there could be bracket-specific responses to contemporaneous state tax reforms (e.g., NJ top-rate change in 2020, CA Prop 30 in 2012, NY/CT top rate tweaks). Consider adding controls for state-specific year dummies interacted with bracket indicators or include state-level top-rate changes as covariates that vary by bracket. Alternatively, exclude states that changed top rates in the post-2018 period to show that the gradient persists.

4. **Migration Mechanism: Inflows vs. Outflows and Net AGI.** The decomposition into outflows/inflows is interesting. You could supplement this with AGI-weighted net migration (in dollars) to demonstrate the fiscal magnitude, as foreshadowed in the idea manifest. Also, examining bilateral flows (e.g., from high-SALT to low-SALT states) around 2018 would provide additional evidence that the rich are relocating to lower-tax jurisdictions rather than, say, moving within the same state but changing filing behavior.

5. **Discussion of Measurement Limitations.** The IRS migration files capture only annual matched returns, which means movers between two states only appear if they filed in both years. Clarify whether deduplication or attrition could bias the income gradient (if wealthier filers are more likely to drop out of the filing universe). If feasible, show that results are robust when using inflows or outflows separately (as you already do) or when weighting by the number of exemptions to account for families.

6. **Robustness to Pandemic-Related Migration.** The pandemic years pose a clear threat. You show results excluding 2020–2021, but it would help to exhibit the coefficients year-by-year to see if there is a discrete jump in 2018 or a gradual drift. Additionally, consider restricting to 2011–2019 for the main triple-difference and presenting those estimates in the main table (with the full sample as baseline). This will reassure readers that the gradient is not driven by COVID-era remote work flows.

7. **Placebo Tests on Low-Exposure States.** You already report a placebo for AGI < \$50K. Complement this with a placebo that uses a “pseudo-treatment” defined by states that had low average SALT deductions but nonetheless classify them as “treated”; one would expect no effect in this exercise. This would further support the claim that the effect arises from increased SALT exposure rather than other state-level characteristics.

8. **Interpretation of Elasticities and Policy Implications.** The paper states that elasticities are concentrated at the top, but it would be helpful to translate the coefficients into back-of-the-envelope elasticities of migration with respect to effective tax rates (e.g., using the implied change in after-tax income from the SALT cap). This would allow direct comparison to the elasticities reported in Young-Varner and Kleven-Landais-Saez and strengthen the policy discussion.

In sum, the paper tackles an important question with rich data and a clever identification strategy. Addressing the above points—particularly the identification/parallel-trends validations and more nuanced treatment intensity measures—would substantially increase confidence in the findings and their contribution to the literature on tax competition and migration.
