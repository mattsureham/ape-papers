# V1 Empirics Check — openai/gpt-oss-120b (Variant C)

**Model:** openai/gpt-oss-120b
**Variant:** C
**Date:** 2026-03-31T16:23:34.448213

---

**1. Idea Fidelity**

The submitted manuscript follows the original manifest closely. It uses the Census Quarterly Workforce Indicators (QWI) disaggregated by race and 2‑digit NAICS, and a state‑quarter measure of anti‑Asian sentiment derived from GDELT (although the paper never shows the GDELT construction, it treats the “post‑COVID” indicator as the treatment rather than a continuous intensity variable). The triple‑difference design (Asian vs White × customer‑facing vs knowledge × pre/post) is exactly what the manifest proposed. The authors also add the “Asian share” interaction that was in the manifest’s continuous‑DDD specification. The only notable departure is the lack of a direct test that the GDELT anti‑Asian index explains variation in the effect; the paper effectively uses a binary post‑COVID dummy instead of exploiting the state‑level variation in the index. Apart from this, the research question, data sources, and identification strategy are faithful to the idea.  

**2. Summary**

The paper documents a large, persistent decline in Asian‑American employment in customer‑facing sectors relative to White workers and to knowledge‑economy sectors after the onset of COVID‑19. Using a triple‑difference framework on state‑quarter QWI data, the authors estimate an 11.3 % (log‑point) drop—about 4,300 Asian workers per state‑quarter—lasting through 2024, and find a symmetric gain in knowledge sectors, suggesting a sectoral reallocation driven by pandemic‑era anti‑Asian sentiment.

**3. Essential Points**

1. **Treatment Specification and Validation**  
   - The manuscript treats the shock as a simple post‑COVID dummy, discarding the continuous GDELT anti‑Asian media intensity that was central to the original design. Without showing that the GDELT index predicts variation in the outcome (e.g., via a dose‑response or interacted specifications), the causal claim that *anti‑Asian sentiment*—rather than the broader pandemic shock—is driving the results is weak. A robustness check using the continuous index (or at least a split‑sample by high/low GDELT intensity) is essential.

2. **Parallel‑Trends Assumption**  
   - The event‑study table includes several pre‑trend coefficients, but the specification mixes very long pre‑period lags (‑12, ‑8) with the immediate pre‑trend. The positive and significant coefficients at ‑12 and ‑8 suggest pre‑existing divergent dynamics that could violate the triple‑difference parallel‑trend assumption. The authors should tighten the pre‑trend window (e.g., only the four quarters immediately before treatment) and present a graph of the coefficients with confidence bands to convince readers that the parallel‑trend holds where it matters.

3. **Interpretation of the “Symmetric” Reallocation**  
   – The claim that the rise in Asian employment in knowledge sectors is “exactly the mirror” of the drop in customer‑facing sectors relies on separate DDD estimates but does not rule out other forces (e.g., overall sector growth, measurement error). The paper should present a joint decomposition (e.g., total Asian employment by sector) to verify that the net change is approximately zero, and discuss any residual growth/decline. Moreover, the mechanism (network‑mediated job search, employer discrimination, voluntary exit) remains completely untested; a modest supplemental analysis (e.g., using ACS occupational mobility tables or Google Trends for job search) would strengthen the story.

**4. Suggestions**

*Data and Treatment Enhancements*  
- **Expose the GDELT Construction**: Include a brief appendix showing how the anti‑Asian media intensity variable is built (keyword filters, co‑occurrence thresholds, normalization). Provide descriptive statistics (mean, variance, correlation with COVID case rates) to reassure readers that the index captures sentiment rather than pandemic severity.  
- **Dose‑Response Checks**: Estimate the DDD with the continuous treatment (as in the manifest’s Panel B) and report the marginal effect per standard deviation of the GDELT index. A clear monotonic relationship would bolster the claim that anti‑Asian sentiment, not just the pandemic, matters.  
- **Alternative Sentiment Measures**: As a robustness, replicate the analysis using Stop AAPI Hate incident counts (available at county level) aggregated to the state‑quarter level, or Google Trends for “anti‑Asian” terms. Consistency across measures would increase credibility.

*Identification and Specification*  
- **Refine Pre‑Trend Window**: The DDD relies on the assumption that Asian‑White gaps in the two sector groups would have evolved similarly absent the shock. Limit the pre‑trend comparison to the four quarters before Q1 2020, and present a visual event‑study plot with 95 % confidence bands. If any pre‑trend is detected, consider adding state‑specific linear trends or a flexible time trend interacted with the Asian × CF term.  
- **State‑Level Heterogeneity**: Since the treatment varies across states, present results allowing for state‑specific post‑trends (e.g., state‑by‑post interaction) or use a random‑effects model to capture differential dynamics. This will address concerns that the binary post‑COVID dummy masks heterogeneity.  
- **Cluster Robustness**: With 51 clusters, conventional cluster‑robust SEs are borderline. Report wild‑cluster bootstrap SEs (Cameron, Gelbach, Miller, 2008) and compare to the conventional ones. If differences are substantive, adopt the bootstrap SEs.

*Mechanism Exploration*  
- **Network Variables**: Exploit the pre‑COVID Asian population share more systematically. For instance, interact the triple‑difference term with the share and plot the marginal effect across the share distribution. This can substantiate the “safety‑in‑numbers” narrative.  
- **Occupational Mobility**: Use ACS 5‑year microdata (or CPS) to track workers who switch from hospitality/retail to professional services between 2019 and 2022, stratified by race. Even a simple transition matrix would illustrate the reallocation path.  
- **Customer‑Facing Intensity**: Within the customer‑facing sector, differentiate between high‑contact occupations (e.g., servers, cashiers) and lower‑contact roles (e.g., managers). If the effect is concentrated among the most exposed jobs, it reinforces a discrimination story.

*Presentation and Transparency*  
- **Figures**: Add a line graph of the event‑study coefficients with confidence intervals, and a map showing the spatial variation in the GDELT anti‑Asian index. Visuals aid intuition and demonstrate the geographic heterogeneity that the DDD exploits.  
- **Descriptive Checks**: Report raw employment levels (not just logs) for Asian workers in each sector before and after, perhaps in a table of differences‑in‑differences, to make the magnitude more tangible for non‑technical readers.  
- **Placebo Tests**: Beyond the fake‑treatment at 2018Q1, consider a placebo using a group that should be unaffected (e.g., African‑American workers) and a sector that is minimally customer‑facing (e.g., utilities). Absence of effects in these placebo groups would further validate the identifying assumption.  
- **Discussion of Alternative Explanations**: Acknowledge that the pandemic itself reduced demand for hospitality jobs, and explain why the White‑worker parallel trend absorbs this shock. Explicitly test whether the residual “COVID demand” effect differs across states (e.g., by incorporating state‑level mobility or lockdown stringency indices).  

*Minor Technical Points*  
- Table 1’s “Mean Emp” numbers are large and the SDs exceed the means, suggesting heavy skewness; consider reporting median values or using log‑transformed outcomes throughout (as you do in regressions) for consistency.  
- In Table 2 (“Standardized Effect Sizes”), the “SDE” for hires and separations is labeled “small negative” despite absolute values around 0.01‑0.03; a brief footnote clarifying the classification thresholds would help.  
- The “Level specification” row in Table 5 reports a coefficient of –5,168 with a p‑value of 0.072; this is an oddly large SE. Consider using heteroskedasticity‑robust (HC3) or Poisson pseudo‑ML for count outcomes, and report the corresponding confidence interval.  

*Conclusion*  

Overall the paper tackles an important and under‑explored channel—anti‑Asian sentiment as a driver of sectoral labor reallocation—using a rich administrative dataset and a plausible identification strategy. To make the causal story convincing, the authors should (i) bring back the continuous anti‑Asian sentiment measure and demonstrate a dose‑response relationship, (ii) tighten and more transparently present the parallel‑trend evidence, and (iii) provide additional evidence of the reallocation mechanism and verify that the net Asian employment change is indeed near zero. Addressing these points will substantially strengthen the paper’s credibility and its contribution to the literature on discrimination, pandemic shocks, and occupational mobility.
