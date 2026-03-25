# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-25T21:51:51.930805

---

**Idea Fidelity**

The paper closely tracks the original manifest. It exploits cross-country variation in pre-ban menthol share as continuous treatment intensity in a dose-response DiD, uses Eurostat HICP data as the primary outcome, incorporates EHIS/other supplementary data sources, and explicitly tackles the COVID timing issue via relative prices and stringency controls. Key elements—uniform May 2020 implementation, menthol market share variation (2–28%), and the focus on substitution versus quit margins—are faithfully represented. The only minor omission is that the manifest mentioned EHIS smoking prevalence data, yet the paper never returns to those smoking outcomes; expanding on this secondary dataset would more directly align with the original plan.

---

**Summary**

The paper evaluates the EU’s 2020 menthol ban by leveraging cross-country variation in pre-ban menthol share as continuous treatment intensity and examining tobacco-specific relative prices in a difference-in-differences framework. Using Eurostat HICP indices and an event-study design (with placebo and triple-difference checks), it finds no detectable effect of the ban on relative tobacco prices, suggesting widespread substitution to non-menthol products rather than decreased demand. The paper concludes that bans targeting product attributes may leave aggregate consumption unchanged when close substitutes exist, with implications for global flavor-ban debates.

---

**Essential Points**

1. **Interpretation of Zero and Power for Detectable Effects:** The constant finding of “no effect” rests critically on interpreting a statistically insignificant coefficient as evidence of substitution, yet the discussion acknowledges that the standard errors allow for economically meaningful effects (e.g., up to ~30% relative-price change in Poland). The authors should clarify the economic magnitude of the null more rigorously—perhaps by reporting confidence intervals around implied country-level effects—and temper the strong mechanistic claims (e.g., “near-complete substitution”) unless supported by additional evidence (e.g., quantity data, quit shares). They also need to transparently report minimum detectable effects for both the continuous and binary specifications (not just the continuous), so readers can assess the power more fully.

2. **Identification Beyond Relative Prices:** The identification strategy heavily relies on the relative price outcome to purge inflation differentials. However, the narrative would benefit from more formal exposition on why the relative-price specification isolates the menthol ban effect rather than simply reflecting price-level offsets. Specifically, the authors should justify that the ratio controls for time-varying confounders (e.g., differential excise hikes, supply shocks) without inadvertently differencing out the treatment effect itself. Including a model or discussion showing that any price change due to the ban would manifest in the numerator but not the denominator (and hence remain identifiable) would solidify this key identification step.

3. **Role of Post-Ban Product Variety and Potential Anticipation:** Menthol-adjacent products (e.g., capsule filters, filter cards) emerged around the ban and may have mitigated price impacts, but the paper does not empirically address them. Without controlling for the availability of compliant substitutes, it is difficult to distinguish substitution within cigarettes from substitution into new product forms (which might not fully comply). The authors should either (a) incorporate data on the market share of these “menthol-compliant” products if available or (b) discuss how their presence would affect the interpretation of the null and whether they might themselves be considered a part of the substitution margin.

If additional critical issues exist beyond these three (e.g., collinearity of menthol share with broader regional trends), the authors might consider rejecting, but current concerns seem addressable.

---

**Suggestions**

1. **Leverage Secondary Data (EHIS or Other Prevalence Measures):** The original plan promised smoking prevalence data (EHIS) to complement price outcomes. Including at least one specification on smoking prevalence—even if only using biennial data with limited time variation—would strengthen the argument about substitution versus quitting. For example, a pre/post comparison for high-menthol countries could validate that aggregate smoking prevalence did not decline post-ban, which would reinforce the price-based inference. If the sample is sparse, emphasize that the prevalence results are suggestive but consistent with the main price findings.

2. **Enhance the Event Study and Pre-Trend Diagnostics:** The event study bins coefficients at $t=-12$ and $t=+24$, but the quantification of pre-trend stability in the immediate leads/trails is pivotal. Consider plotting the full event study (with confidence intervals) and including a formal test for differential pre-trends (e.g., a joint F-test for the lead coefficients). Visual presentation would reassure readers about the absence of pre-treatment dynamics. Additionally, the authors might check for placebo “pseudo-treatment” dates (e.g., placebo ban six months earlier) to assess whether the method would falsely detect effects.

3. **Explicitly Address Clustering Concerns:** With only 28 treated units, the clustered standard errors may still underestimate the true variability. The paper mentions difficulties with the wild cluster bootstrap but does not report the results. Including the outcome of that exercise—even if it failed, explain why—would help reviewers gauge inference robustness. Alternatively, the authors could implement randomization inference (permutation of menthol shares across countries) or a Bayesian hierarchical model to provide complementary uncertainty estimates under limited clusters.

4. **Disentangle Menthol Share from Regional Covariates:** Menthol prevalence is correlated with geography and other structural factors (e.g., income, excise levels). Including time-varying controls such as per-capita income, cigarette excise tax changes, or energy price exposure (beyond general inflation) could bolster confidence that the differential price dynamics stem from the ban rather than broader regional shocks. If data are unavailable for the full period, the authors might show that including available controls (e.g., GDP growth, unemployment) does not alter the result.

5. **Examine Quantity or Revenue Proxies if Possible:** The current focus on prices leaves the possibility that quantity falls offset price increases, resulting in a flat price index. While quantity data at monthly frequency may not exist, the authors might explore annual excise revenue or PRODCOM production data as complementary checks. Even if these are coarse, matching them to the intensity measure could reveal whether total cigarettes sold or tobacco production changed more in high-menthol countries. If the data do not align well, discussing their limitations would still inform the substitution interpretation.

6. **Clarify the Mechanism of Substitution:** The Discussion section argues that the ban removed an attribute rather than the product, implying near-perfect substitution. To make this more credible, the authors might (a) reference industry evidence on the price gap between menthol and non-menthol cigarettes before the ban, showing they were priced similarly, and (b) cite behavioral studies (e.g., cessation rates) that quantify the proportion of menthol smokers that switched. If possible, compute simple back-of-the-envelope calculations showing that maintaining the same aggregate price index is consistent with substitution shares observed in the surveys.

7. **Frame Policy Implications with Caveats:** The concluding policy advice—that flavor bans need to be paired with price instruments—is provocative but should be couched carefully. Highlight that the paper studies existing smokers and market-level prices, so it may not speak to initiation effects among youth or long-term cessation trends. Suggest that future research should combine the current findings with individual-level data on initiation/quitting to provide a more complete cost-benefit assessment of flavor bans.

8. **Improve Clarity on Sample Construction and Data Sources:** While Table 1 describes the data, additional transparency would help replication. Provide an appendix table listing menthol shares by country and source, specify how missing data were handled (e.g., were countries dropped or interpolated), and clarify why the May 2020 transition month is excluded. Also, mention whether the UK data post-Brexit are fully comparable given potential divergence in HICP compilation.

9. **Consider Nonlinear Treatment Effects:** The dose-response design assumes linearity between menthol share and the price outcome. It may be worthwhile to test whether effects jump above certain thresholds (e.g., >15% share) or whether the marginal effect diminishes at higher shares. This could be done via spline regressions or quantile splits, providing insight into whether the substitution mechanism operates uniformly across exposure levels.

10. **Expand the Discussion of External Validity:** The paper could better situate findings within the broader literature on flavor bans (e.g., references to US proposals, Canada’s experience). Are there features unique to the EU market (e.g., high cross-border purchasing, excise harmonization) that limit extrapolation to other jurisdictions? Discuss how differences in enforcement, market structure, or smoker heterogeneity might affect whether substitution dominates cessation elsewhere.

These enhancements would reinforce the credibility and policy relevance of the paper while maintaining its concise AER: Insights-style format.
