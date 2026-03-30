# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-30T14:32:21.036830

---

**Idea Fidelity**

The paper closely follows the manifest’s proposal. It builds a Bartik-style instrument using pre-determined county patent shares and quasi-random examiner leniency shocks, merges USPTO exam data (via BigQuery/PatentsView) with county-level QWI labor market outcomes, and focuses on employment, hires, separations, and earnings. The author explicitly notes the shift-share construction, leave-one-out examiner grant rates, and the Heckman-Goldsmith-Pinkham-type identification conditions. Key elements—examiner variation, county technology composition, and the policy-relevant question of whether patent grants drive local labor demand—are all present. The paper even replicates the suggested robustness checks (state×year fixed effects, pre-trend, sectors), so fidelity to the idea manifest is high.

**Summary**

The paper studies whether examiner-induced patent grants causally affect county-level employment by instrumenting patent grants with a Bartik-style combination of pre-determined county art-unit shares and examiner leniency shocks from the USPTO. OLS suggests a small positive elasticity, but the 2SLS estimate is negative and statistically null, implying that the observed positive correlation between patents and employment stems from sorting rather than causal impact (“patent payroll illusion”). The null result persists across LIML, state-by-year fixed effects, sector splits, and pre-trend placebo tests.

**Essential Points**

1. **Local Spillovers and Timing:** The empirical model treats log employment at \(t+1\) as the outcome, yet patent grants may take several years to affect commercialization or firm hiring. The narrative should justify why a one-year lead is sufficient, or present results over longer horizons (e.g., \(t+2\), \(t+3\)) to ensure the null isn’t driven by mistimed effects. Without this, the interpretation that patents have no employment effect could be premature.

2. **First-Stage Interpretation & Mechanism:** The instrument’s interpretation rests on the examiner-level variation aggregating to county-level shocks via fixed shares. However, the paper does not show how much of the county patent flow is driven by these examiner shocks (e.g., share of variance explained). Presenting the decomposition of the first-stage variation (e.g., F-statistic alone is insufficient) and discussing whether the instrument captures marginal, low-propensity applications (the “marginal” patents) would clarify what margin the null pertains to. Otherwise, readers may misinterpret the estimate as ruling out any patent employment effect beyond this margin.

3. **External Validity and Sample Selection:** The sample is restricted to 876 counties with ≥20 patent applications during 2001–2003, which are likely the most patent-intensive and urban counties. The paper should discuss how representative this sample is for broader local labor markets and whether the null might reflect these high-innovation locations (e.g., they may already be at capacity). Additionally, the potential for differential migration or intra-county sorting in this sample could confound the interpretation of a null effect as general policy evidence.

**Suggestions**

- **Dynamic Effects:** Expand the dynamic analysis. Table 3 reports only a placebo at \(t-1\), but to claim that patents don’t affect employment, it would be helpful to report results using employment at \(t+2\) or \(t+3\), as well as cumulative effects over multiple years. If data limitations preclude longer leads, explain clearly why the \(t+1\) outcome captures the relevant window (e.g., most patent-induced hiring occurs within a year because firms immediately respond to USPTO decisions).

- **Share Construction and Measurement Error:** The paper notes that county shares are calculated using granted patents (PatentsView)—a potential concern because grants, not applications, determine shares, and leniency affects grants. While the authors argue that the Borusyak et al. framework only requires exogenous shocks, they should quantify the potential attenuation bias by simulating or instrumenting using shares computed from earlier data (e.g., pre-2001). Alternatively, they could show that the estimated shares are stable over time and correlate highly with broader application counts, alleviating measurement-error worries.

- **Mechanism Clarification:** The null could mean multiple things: examiner-induced patents shift rents without employment effects, marginal patents are not large enough, patents affect employment outside the inventor’s county (e.g., headquarters elsewhere), or benefits manifest through productivity rather than employment. The paper could discuss and, where possible, test these channels—for instance, by examining employment in the county of the assignee (if data permit) or by checking whether patent-induced grants affect firm-level wages (with matched firm data) to see if the benefits accrue differently.

- **Strength and Exclusion Restriction Evidence:** Beyond the F-statistic, present diagnostics for instrument strength and exclusion. For example, show the distribution of leave-one-out leniency shocks and the implied variation in county patent flows; or report reduced-form correlations between the instrument and other local shocks (e.g., lagged investment or construction permits) to reassure readers that the instrument only affects employment via patents. Including placebo outcomes (e.g., county housing starts) could also bolster the exclusion argument.

- **Interpret Null Carefully:** Throughout, the narrative leans toward a bold policy conclusion (“patents don’t create jobs”). Given the weak precision of the IV (SE=0.044, so confidence intervals are wide), the paper should frame the result more cautiously as evidence that the marginal effect is small and statistically indistinguishable from zero within the examined sample and margin. Consider presenting confidence intervals (e.g., 95% CI covers approximately ±0.086) to show the range of plausible effects and to avoid overstating the null.

- **Heterogeneity Beyond Sectors:** The manifest promises demographic heterogeneity (age, education, race) via QWI’s disaggregated cells, but the paper only splits by broad sector groups. If feasible, add heterogeneity by skill/education (e.g., college vs. non-college workers) since the policy question is whether patent-led innovation benefits high-skill local workers. Even if limited to a subset of counties or years, such results would enrich the paper’s contribution and better align with the novel data promise.

- **Power Calculations:** Since the paper hinges on a null finding, provide a more formal discussion of statistical power. What is the minimum detectable effect (MDE) given the sample size, instrument strength, and outcome variance? Table \ref{tab:sde} gives standardized effects, but interpreting whether the null is meaningful requires knowing how large of an effect the study could have detected with high probability. This would also contextualize the “patent payroll illusion” claim.

- **Address Potential Spillovers to Nearby Counties:** Patents granted to inventors in a county may lead to employment impacts in neighboring counties (due to commuting, supply chains). If the instrument shifts grants in one county but employment effects spill over elsewhere, the estimated county-level effect could be attenuated. Consider including neighboring counties’ outcomes as placebo or expanding the analysis to commuting zones.

- **Clarify the Mechanism Section:** In Table \ref{tab:mechanism}, the negative (but noisy) effects on hires and earnings hint at potential phenomena. The text should interpret these carefully: do they support the idea that patent grants shift resources toward rents (earnings) or away from hiring? Even if not conclusive, discuss whether these patterns align with theoretical expectations for examiner-leniency-induced patents.

- **Reproducibility and Code:** Since the paper states it was autonomously generated and points to a GitHub repo, ensure that the code and data pipelines used (particularly for the examiner leniency calculations) are documented and available (subject to licensing). A short appendix describing the data construction steps (e.g., how examiner shocks are aggregated) would help future replicators and reviewers verify the shift-share IV.

Overall, the paper tackles an important question with a credible identification strategy, but it should elaborate on timing, share construction, heterogeneity, and inferential limits to strengthen the conclusions and policy relevance.
