# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-23T13:50:48.073694

---

**Idea Fidelity**

The manuscript remains faithful to the original idea manifest: it exploits the 2011 mass revocation as a cross-county natural experiment to test whether removing “zombie” nonprofits generates creative destruction or collateral damage. The paper keeps the promised data sources (IRS revocation lists, EO BMF formations, QWI employment, SOI deductions) and maintains the continuous-treatment DiD identification strategy with county and year fixed effects plus event-study dynamics. No major component of the original research plan—policy context, outcomes, or the competing hypotheses—was dropped. One minor discrepancy is that the paper does not yet fully interrogate the hypothesis that revocation intensity reflects “historical composition” rather than contemporaneous shocks; further discussion of this point would strengthen fidelity to the manifest argument. Overall, the submitted draft is well aligned with the stated idea.

---

**Summary**

The paper studies the 2011 IRS mass revocation of tax-exempt status for non-filing nonprofits, leveraging cross-county variation in the share of pre-2010 nonprofits revoked to estimate effects on new formations, sector employment, and giving. A continuous-treatment DiD shows an initial uptick in new formations consistent with creative destruction, but this effect reverses within a couple of years and yields a medium-run net decline in formations and employment. The author interprets the results as evidence that mass de-registration damages the local nonprofit ecosystem rather than freeing up resources.

---

**Essential Points**

1. **Parallel trends and time-varying confounders:** The identification assumes that, absent revocation, counties with different revocation intensity would have followed similar formation trajectories. Yet counties with high shares of pre-2010 nonprofits (the treatment) are likely those with older, smaller, and potentially less professionalized nonprofit sectors—possibly experiencing different time trends due to demographic, economic, or policy shifts. The event study shows a marginally significant negative coefficient in year $t=-2$, which may flag emerging divergence even before treatment. The current robustness checks (trimming, placebo) are insufficient to rule out these confounders. I recommend including richer pre-treatment controls (e.g., interacting lagged socioeconomic covariates with time, allowing for county-specific quadratic trends, or implementing estimators that weight more heavily on pre-period matches such as synthetic control or entropy balancing). Without better addressing this threat, the causal interpretation is fragile.

2. **Interpretation of formation outcome:** The principal outcome is measured by IRS ruling dates, which reflect administrative recognition rather than actual startup activity, and may itself be influenced by IRS processing capacity or reporting delays that vary systematically with revocation intensity. For example, counties with fewer active nonprofits may see less administrative attention, depressing observed formations. The paper briefly acknowledges this but does not provide hard evidence either way. To sustain the main claim about creative destruction versus collateral damage, the author should provide additional validation—e.g., showing that formation counts correlate with independent local indicators (media reports, state-level registrations), exploiting alternative timing (ruling delays), or using placebo outcomes that should be unaffected by IRS processing.

3. **Employment and giving results need stronger linkage:** The employment finding is in line with the story, but the effect attenuates with population controls and could simply reflect broader demographic shifts rather than nonprofit-specific dynamics. The charitable deductions outcome is purely cross-sectional, so causal claims are unwarranted. I suggest the author either reframe these results as descriptive correlations or find additional panel data (even at the state level) to difference out confounders. Otherwise the employment/giving results add little to the central argument.

If more than three critical issues are needed, the paper likely needs additional revision before resubmission.

---

**Suggestions**

- **Strengthen identification:** Extend the robustness suite to include county-specific quadratic or higher-order time trends, interacted pre-treatment controls, or matched samples based on pre-2010 formation trajectories. Consider a stacked DiD that uses different cohorts of counties entering treatment intensity buckets, or a dose-response regression that exploits within-county variation in the timing of data availability to better isolate the treatment effect. Providing graphical evidence that counties with different revocation intensities had similar trends in other sectoral or demographic outcomes prior to 2011 would bolster credibility.

- **Mechanism exploration:** The inverted-U dynamic is central to the argument. To unpack the “false spring” vs. “collateral damage” story, the author could look for intermediate outcomes—such as the share of restituted organizations, grantmaking activity (if data exist), or measures of nonprofit collaboration networks (e.g., IRS filings referencing fiscal sponsors). Alternatively, examine whether the negative medium-run effect is concentrated among certain sub-sectors (religious vs. civic) or regions, which might reveal whether institutional infrastructure (donor networks vs. IRS capacity) is driving results.

- **Address the interpretation of revocation intensity:** Because revocation intensity is the ratio of revoked nonprofits to pre-2010 stocks, it conflates the absolute number of revoked organizations with the density of the nonprofit sector. A county with a vibrant but filing-delinquent sector could have the same intensity as one with a small but entirely dormant sector, yet the implications differ. Reporting results where the numerator and denominator enter separately—e.g., interacting the absolute number revoked with pre-period nonprofit density—could help clarify whether the effects stem from clearing zombies or from the structural characteristics of the local ecosystem.

- **Clarify policy implications:** The conclusion suggests that maintaining dormant organizations might be less costly than revoking them, but this inference depends on the assumption that the observed harms are driven by the revocation policy itself rather than other concurrent shocks. It would help to compare counties affected by later waves of revocation (post-2011) to see whether the negative medium-run dynamics replicate, or to analyze counties where reinstatement rates were higher. This would provide guidance on whether modifying enforcement timing or offering reinstatement assistance could mitigate the collateral damage.

- **Data transparency and replication:** Given the reliance on IRS administrative sources, include appendix figures summarizing the geographic distribution of revocation intensity, pre-treatment formation trends, and the share of revocations matched to counties. Providing code or a clear description of the geocoding process would enhance reproducibility and allow others to assess whether measurement error might bias results.

- **Event study standard errors:** The event study (Table 3) reports point estimates without confidence bands. Plotting the coefficients with 95% CIs would help readers assess the statistical significance of the dynamic pattern visually. If possible, re-run the event study with alternative bandwidths/omitting leads/lags to ensure the negative medium-run effects are not driven by a few years of noisy data.

Incorporating these suggestions would clarify the causal story, reinforce the substantive narrative, and make the policy takeaway more convincing.
