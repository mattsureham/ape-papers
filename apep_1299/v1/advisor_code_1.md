# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-04-02T04:39:39.434173

---

**Idea Fidelity**

The paper largely stays true to the manifest: it uses the EOIR case-level data, aggregates asylum outcomes to nationality-year cells, and constructs the leave-nationality-out judge leniency IV exactly as described. The outcome is remittance inflows from the World Bank, the instrument is the aggregated judge leniency, and the key research question remains the deportation dividend for origin countries. The only deviation from the original idea is that the resulting estimate is a precise null, which the authors explore comprehensively.

---

**Summary**

This paper asks whether variation in asylum grant rates—induced by quasi-random judge assignment within US immigration courts—affects aggregate remittance inflows to the applicants’ origin countries. Using a leave-nationality-out judge leniency IV and a panel of 29 origin countries over 2001–2023, the authors find a precisely estimated zero effect of asylum grants on total remittances, with a strong first stage but a 2SLS point estimate that is negative and statistically insignificant. The paper frames this finding as a “missing deportation dividend,” arguing that marginal asylum decisions do not move macro remittance volumes.

---

**Essential Points**

1. **Clarify and test the exclusion restriction of the nationality-level instrument.** Aggregating judge leniency to the origin-country level raises the possibility that countries with worsening conditions (which also affect remittances) end up seeing different judge compositions—e.g., if certain nationalities are concentrated in particular courts or judges. The paper should provide direct evidence that, conditional on court-by-year fixed effects, fluctuations in judge composition are unrelated to nationality-specific shocks. Balance tests showing that nationalities are not systematically channeled to lenient or strict judges over time, or regressions of the instrument on leading origin-country economic/political shocks, would help bolster the exclusion claim beyond the FDI placebo.

2. **Address the measurement limitations of the remittance outcome more rigorously.** The World Bank series aggregates remittances from all host countries, whereas the treatment operates through US immigration courts. This introduces classical measurement error but also attenuates statistical power and may explain the null. The authors briefly mention this in the discussion; they should quantify the implied attenuation (e.g., using US share of remittances) or, ideally, replicate the main result using available bilateral US-to-country flows (even if for a smaller subset) to demonstrate the effect is still null when measuring the relevant channel more precisely.

3. **Connect the estimated local average treatment effect to the scale of remittance flows.** The first stage demonstrates substantial variation in grant rates, but the paper does not translate that into the number of additional allowed asylum seekers or their income contributions. Since one of the interpretations for the null is that marginal asylees are a small fraction of diasporas, the paper should quantify how many additional migrants remain in the US per standard deviation increase in the grant rate (i.e., via the number of cases affected) and compare that to the total stock of remittance senders. Without this, it is hard to judge whether the null reflects a genuine lack of effect or simply an economically small treatment.

---

**Suggestions**

- **Disaggregate the instrument by court or judge pools.** The paper currently averages leniency across all judges serving a nationality in a given year. It would be helpful to show that this aggregation is not driven by a few courts or judges that specialize in certain nationalities. For example, construct instruments at the court-nationality-year level and demonstrate the main result holds when focusing on the within-court variation, which would directly link the identification to the documented random assignment within courthouses.

- **Explore alternative units of analysis.** The current outcome is total remittances in levels (logged). Because the treatment operates through a small margin, analyzing remittances per migrant or remittances per capita might reduce noise from country size and better capture the relative importance of the affected cases. Likewise, considering remittances as a share of GDP (which is presented in summary statistics) could align more closely with policy discussions around dependence.

- **Leverage additional outcomes or subgroups to trace the mechanism.** If the labor-income channel is operative, one would expect asylum grants to raise legal employment, taxable earnings, or banking access for affected individuals. While administrative data may not allow that, the authors could use DHS/LSMS consumption or course-specific DHS questions from a few countries (as mentioned in the manifest) to explore whether remittances increase among certain sub-populations, even if aggregate flows do not move. Alternately, they could examine country-level unemployment rates or consumption growth around the instrument to ensure no spillover channels are masking the effect.

- **Strengthen the placebo tests.** The FDI placebo is useful, but FDI is driven by entirely different actors and may be too noisy. A more relevant placebo would be another migrant-sent income stream that should not respond to asylum decisions (e.g., foreign aid receipts, intra-national transfers). Similarly, using the instrument to predict remittances of countries not in the sample—or pre-2001 remittances before the asylum cases exist—could further validate the exclusion restriction.

- **Discuss potential sample selection.** The analysis restricts to nationality-year cells with at least 100 resolved cases, which may bias the sample toward countries with large US diasporas. How might the results extend (or not) to smaller-origin countries, especially those where remittances are relatively more concentrated? If feasible, the authors could test whether including cells with fewer cases changes the results, even if the variance of the grant rate estimate increases.

- **Report more diagnostics on the instrument.** Providing the within- and between-country variation of the instrument, the share of variation explained by court-year versus nationality-time, or the distribution of first-stage fitted values would help readers understand how much of the identifying variation comes from small vs. large countries. Additionally, reporting the mean number of judges per nationality-year alongside the instrument distribution (perhaps in an appendix figure) would contextualize the strength of the leverage.

- **Consider alternative inference given a small number of clusters.** The authors already report two-way clustering, but with only 29 countries the standard errors may still be fragile. Bootstrapped confidence intervals (e.g., wild cluster bootstrap) or reporting randomization-inference-style p-values could supplement the inference and reassure readers that the null is not driven by imprecise standard errors.

- **Elaborate on heterogeneity by immigration policy regimes.** The effect of asylum grants on remittances may depend on broader policy contexts—e.g., countries facing increased interior enforcement or visa restrictions might see different responses. The paper could interact the instrument with measures of US enforcement intensity (e.g., changes in EAD processing times, detention policies) to test whether the link between legal status and remittances strengthens when the broader environment is more hostile.

By addressing these points, the paper can more convincingly argue that marginal asylum decisions truly have negligible aggregate remittance consequences, rather than the null simply reflecting measurement challenges or small treated populations.
