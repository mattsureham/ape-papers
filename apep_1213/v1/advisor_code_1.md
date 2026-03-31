# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-31T16:19:36.820728

---

**Idea Fidelity**  
The paper largely adheres to the manifest: it studies the Moldovan “stolen billion” crisis, exploits geographic variation stemming from BEM’s Soviet-era footprint, and focuses on employment effects using raion-level StatBank data. One area where the implementation diverged is in the treatment variable: the manifest emphasized pre-crisis branch exposure of BEM (and the orthogonal institutional inheritance), whereas the paper operationalizes dependence via the **inverse** share of financial-sector enterprises in each raion. This proxy is plausible, but it is not shown to be tightly correlated with actual BEM branch density, and no direct branch data are introduced. The manifest also promised the use of World Bank Enterprise Survey microdata for credit channels, but that data source is not reflected in the current draft.

---

**Summary**  
This paper studies the employment consequences of the November 2014 Moldovan banking crisis, which wiped out state-linked lenders including the Soviet‑inherited Banca de Economii (BEM). Exploiting raion-level variation in pre-crisis dependence on BEM—captured by the inverse share of financial enterprises—the author estimates that more dependent districts experienced an 8% employment decline that persisted through 2024, without a corresponding fall in firm counts. The paper interprets this pattern as a credit-constrained “zombie firm” response to a supply-side shock whose timing and geographic reach are plausibly exogenous.

---

**Essential Points**

1. **Treatment measurement and instrument validity.** The paper relies on the inverse share of financial enterprises as a proxy for BEM dependence, but it never demonstrates that this measure is a good surrogate for the actual geographic distribution of BEM branches. Given that the identifying claim hinges on Soviet administrative legacies, readers need evidence—either direct branch-level data from NBM/BEM archives or a validation exercise—that the proposed proxy is tightly correlated with BEM’s pre-crisis footprint and not picking up other regional characteristics (e.g., broader financial development). Without such validation, it remains unclear whether the treatment really captures the institutional inheritance the paper invokes.

2. **Pre-trends and parallel-trend assumption.** The event study shows significant coefficients in the early pre-period (2005–2009) and formally rejects parallel trends over 2005–2013. The preferred inference relies on restricting the pre-period to 2010–2014, but this restriction is neither reflected in the main specifications nor exhaustively documented. To sustain the DiD interpretation, the paper must demonstrate that results are robust to flexible pre-trend controls (e.g., raion-specific linear/quadratic trends, spline adjustments anchored at 2010) and transparently present the restricted pre-period regressions. Given the small number of units, any remaining pre-trend threatens identification, so the reviewer needs to see either (a) the event study after 2010 shows flat leads or (b) an estimator immune to differential trends (e.g., Callaway–Sant’Anna with dynamic weights) yielding similar magnitudes.

3. **Mechanism and credit channel evidence.** The paper posits a credit-supply-driven “zombie firm” channel—loss of hiring without exit—but the empirical support is thin. Aggregate employment and enterprise counts alone do not rule out alternative explanations (e.g., sectoral shocks, migration). The manifest alluded to the World Bank Enterprise Survey, which could provide firm-level evidence on credit constraints or bank relationships before and after the crisis. At minimum, the paper should present direct evidence that BEM-dependent raions experienced sharper contractions in credit supply (loan growth, interest rates, usage of BEM), or that firms reported greater difficulty accessing finance. Without such evidence, the interpretation as a supply-driven zombie channel remains speculative.

---

**Suggestions**

1. **Strengthen the treatment variable construction.**  
   - **Obtain direct branch data if possible.** If historical branch lists exist (e.g., NBM supervisory reports, archived BEM annual reports), use them to construct the pre-2014 BEM branch share of total branches per raion. This would anchor the treatment firmly in the institutional inheritance story.  
   - **Validate the proxy.** If direct branch counts are unavailable, show that the inverse financial-enterprise share strongly predicts documented BEM presence (e.g., correlate the proxy with known branch locations for a subset of raions, use anecdotal sources, or rely on OpenStreetMap/legacy data).  
   - **Explore alternative proxies.** Consider other pre-crisis indicators of state-bank dominance—such as the share of deposits held in state banks, the presence of state procurement offices, or Soviet-era infrastructure investments—and check whether estimated effects are robust to those definitions.

2. **Enhance the causal design by addressing differential trends.**  
   - **Re-estimate using a 2010–2014 “clean” pre-period.** Present a main specification that uses only the years with flat pre-trends, or explicitly interact the treatment with a 2010–2014 linear trend to soak up pre-existing dynamics.  
   - **Include raion-specific flexible trends.** Add interactions of BEM dependence with polynomial time trends (e.g., quadratic) or time dummies pre-2014 to soak up any remaining differential paths.  
   - **Leverage recent DiD advances.** Use approaches such as Callaway and Sant’Anna (2021) or de Chaisemartin and D’Haultfœuille (2020) that permit heterogeneous trends and treatment timing or rely on event-study estimators that are robust to dynamic treatment effects. While there is a single shock date, these methods can still test whether later post-period effects are driven by pre-trend contamination.

3. **Bolster the mechanism narrative with micro-level evidence.**  
   - **Use the World Bank Enterprise Survey.** Leverage the 2013 and 2019 waves to show that firms in high BEM-dependence raions had worse access to finance (e.g., lower likelihood of bank relationships, higher share reporting collateral constraints) before/after the crisis. A difference-in-differences at the firm level would complement the raion analysis and directly tie credit supply conditions to employment adjustments.  
   - **Exploit any available loan-level or credit registry data.** Even if full loan books are unavailable, supervisory reports might record loan growth by region or bank. Demonstrating a sharper decline in new lending or outstanding credit in BEM-dominated raions would directly support the supply-shock claim.  
   - **Investigate occupation or wage data.** If employment shrank without firm exits, wages or hours might adjust differently in dependent raions. Even anecdotal or qualitative evidence (interviews, reports) could fortify the zombie-firm framing.

4. **Clarify turnover results and inflation adjustments.**  
   The turnover estimates are positive but imprecise. The paper speculates that nominal inflation accounts for this, yet log outcomes already adjust for uniform inflation. Consider deflating turnover by CPI or wage inflation to see whether real turnover declines mimic employment losses. Alternatively, present sectoral turnover (e.g., manufacturing versus services) to check whether the credit shock hit certain industries more sharply and whether aggregate turnover masks aubstitutions.

5. **Discuss potential spillovers and general equilibrium considerations.**  
   The narrative focuses on local credit constraints, but there might be spillovers (e.g., migration of labor to Chisinau). Explore whether high-dependence raions see relative population declines, changes in migration, or differential public investment. Even if data are limited, noting these channels and speculating on their possible moderating effects would improve the policy relevance of the “Soviet inheritance trap.”

6. **Be transparent about statistical power and inference.**  
   The small number of clusters is a limitation. Alongside wild bootstrap p-values, report confidence intervals from the bootstrap/randomization inference so readers understand the substantive uncertainty. If feasible, consider aggregating raions with similar pre-trends or employing randomization inference with alternative sharp nulls to demonstrate robustness to clustering concerns.

7. **Revisit the conclusion to tie back to the manifest.**  
   The idea manifest highlighted the policy paradox of state banks in transition economies. Make sure the conclusion reiterates how the empirical findings inform debates on state-owned bank reform—not only in Moldova but for other post-Soviet countries with inherited branch networks. Adding a brief comparison to PrivatBank’s nationalization or Russian/Sberbank geography (even if only descriptive) would situate the contribution within broader policy discussions.

By addressing these points, the paper will solidify its identification, enrich the credit-supply narrative, and better fulfill the promise of the original manifest.
