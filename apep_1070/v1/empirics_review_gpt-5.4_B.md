# V1 Empirics Check — openai/gpt-5.4 (Variant B)

**Model:** openai/gpt-5.4
**Variant:** B
**Date:** 2026-03-27T13:31:56.698276

---

## 1. Idea Fidelity

The paper broadly pursues the manifest’s core question: whether county-level H-2A expansion displaced Hispanic domestic farm workers, using DOL certification data merged to QWI ethnicity-industry outcomes and a county-by-time-by-ethnicity design. It also retains several proposed elements, including placebo industries, separations/hires as mechanisms, and a Bartik-style IV.

That said, it misses or alters several key elements in ways that matter for identification. Most importantly, the manifest envisioned using H-2A data back to 2012 to exploit the full 2012–2022 expansion and to support pre/post/event-study logic. The paper instead uses only FY2018–2023 H-2A data while claiming pre-trend evidence for 2010–2017, when treatment is unobserved in the data. This is not a minor implementation detail; it undermines the central design. The fixed-effects structure also differs from the manifest (state×quarter rather than state×ethnicity), and the paper’s IV is not well aligned with the manifest’s stated goal of isolating demand-side variation. So the paper follows the spirit of the idea, but not its strongest empirical version.

## 2. Summary

This paper studies whether the rapid expansion of the H-2A guestworker program reduced employment of Hispanic domestic workers in agriculture. Using county-level H-2A certifications and QWI county-quarter-ethnicity cells, the paper reports negative OLS associations but a null IV effect, and concludes that apparent displacement is due to selection rather than causation.

The topic is important and the data combination is potentially valuable. However, the current paper does not yet convincingly establish a causal null effect, because the treatment measurement window, event-study logic, sample construction, and especially the IV strategy are not sufficiently credible relative to the strength of the paper’s claims.

## 3. Essential Points

1. **The identification strategy is not coherent as written, especially the “pre-trend” and event-study analysis.**  
   The paper states that H-2A treatment data begin in 2018, yet it repeatedly refers to a pre-period of 2010–2017 and presents an event study relative to “Pre (2010–13)” using interactions with ln(H-2A). If H-2A is unobserved before 2018, then there is no county-level treatment variation to estimate pre-trends in the way described. This is a first-order problem. The paper must either (i) extend the H-2A data backward as envisioned in the manifest, or (ii) abandon claims about pre-trends and recast the design as a post-2018 dose-response panel with much weaker identifying content.

2. **The Bartik IV is currently unconvincing and likely does not solve the core endogeneity problem.**  
   The instrument uses a county’s 2018 share of state H-2A positions interacted with national H-2A growth. Counties with larger 2018 H-2A shares are precisely the counties most specialized in labor-intensive crops and most exposed to persistent trends in domestic Hispanic farm labor supply. That creates a serious share-endogeneity problem. In addition, with state×quarter fixed effects, much of the identifying variation appears to come from cross-county differences in initial shares interacted with a common aggregate trend, which can mechanically produce an enormous first stage without making the exclusion restriction plausible. The paper needs a much fuller justification and standard shift-share diagnostics; absent that, the IV result cannot carry the paper’s causal claim.

3. **Data construction and sample selection are not transparent enough to support the conclusions.**  
   The QWI Hispanic agriculture cells are heavily suppressed in many county-quarter observations, yet the paper does not clearly explain how zeroes, suppressed cells, and missing outcomes are handled in the log specifications. The sample sizes vary substantially across outcomes, and the DOL county match rate is only 91%, with apparently nonrandom failures. Because the estimated effects are small, the paper must show that coding and sample selection are not driving the results. As written, the paper’s data quality discussion is too thin for a causal paper making a strong “mirage” claim.

## 4. Suggestions

The paper is asking a very good question, and the combination of DOL disclosure records with QWI is promising. I think the project could become a useful descriptive or quasi-causal contribution, but it needs a more disciplined empirical design and a more modest interpretation. Below are concrete suggestions.

**First, rebuild the treatment series to match the original idea.**  
The manifest’s strongest feature was the long H-2A buildup from 2012 onward. If those files are available, the paper should absolutely use them. A 2012–2022 county-year treatment series would allow:
- actual pre-period comparisons before the steepest growth,
- a coherent event-study around cumulative expansion,
- testing whether counties with high later H-2A growth already had differential Hispanic/non-Hispanic employment trends before 2018,
- and a more informative decomposition of the 2020–2023 period, which is otherwise confounded by COVID and other shocks.

If the authors cannot recover the earlier data cleanly, they should substantially narrow the claims. In that case, the paper is not identifying “the expansion of H-2A” in a broad historical sense; it is analyzing a short post-2018 period with limited pre-treatment information.

**Second, clarify exactly what the DDD is buying you.**  
The paper says the third difference compares Hispanic to non-Hispanic workers “within the same county and quarter, absorbing any county-time shocks that affect all workers equally.” But the regression does not include county×quarter fixed effects, so it does not literally absorb all county-time shocks. Instead, it assumes those shocks affect Hispanic and non-Hispanic workers similarly conditional on the included FE structure. That assumption may be reasonable in some contexts, but in agriculture it is not innocuous: crop mix, seasonality, subcontracting, and migrant network effects could differentially affect Hispanic workers. I suggest:
- explicitly stating the identifying assumption in those terms,
- reporting a model in first differences of the Hispanic/non-Hispanic employment ratio at the county-quarter level,
- and, if feasible, estimating specifications with county-specific trends by ethnicity or county-specific linear trends in Hispanic share.

A cleaner presentation would be to rewrite the estimand as “the differential response of Hispanic relative to non-Hispanic agricultural employment to H-2A growth,” rather than implying full county-time shock absorption.

**Third, treat the IV section much more cautiously and provide the diagnostics that shift-share designs now require.**  
At minimum, the authors should:
- show the first-stage graphically,
- report the effective identifying variation after fixed effects,
- discuss why the 2018 county share is plausibly exogenous to subsequent Hispanic domestic labor trends,
- test whether initial share predicts pre-2018 trends in Hispanic agricultural employment, hires, separations, and earnings,
- report robustness to alternative share definitions (e.g., 2012 share if available, or leave-one-out state/national growth),
- and consider a more standard leave-one-out shift-share instrument.

The paper currently interprets the IV estimate as “the truth” and OLS as selection bias. That conclusion is too strong. A null IV with a potentially invalid instrument does not establish no displacement. It may simply reflect that the instrument isolates exposure among counties already structurally reliant on H-2A. The right framing is that IV attenuates the negative OLS relationship under a particular source of variation, not that it definitively proves a “mirage.”

**Relatedly, the exclusion restriction needs a sharper economic story.**  
National H-2A growth may itself be correlated with national shocks that differentially affect counties with larger baseline H-2A shares: changes in commodity prices, labor-intensive crop profitability, immigration enforcement, border policy, or weather patterns. Those counties are not random. The paper should engage this directly instead of assuming that interaction with aggregate growth is demand-driven and therefore exogenous.

**Fourth, improve the treatment measure and discuss what certifications mean.**  
DOL certified positions are not the same as visas issued or workers employed, and certification intensity may also vary with application practices, legal compliance, and multi-crop seasonality. The paper should:
- discuss the gap between certifications and realized worker counts,
- show whether results change using approved applications, requested positions, or employer counts if available,
- normalize certifications by baseline agricultural employment or acreage,
- and examine whether large effects are concentrated in counties where H-2A certifications are very large relative to observed domestic agricultural employment.

A useful figure would show the ratio of H-2A certified positions to QWI agricultural employment by county-year. If many counties have certification counts comparable to or exceeding domestic employment, that has implications for interpretation.

**Fifth, be much more transparent about the QWI data limitations.**  
This is especially important because Hispanic agriculture cells are often sparse. The paper should explain:
- whether zero values are true zeroes or missing/suppressed observations,
- how logs are formed when outcomes are zero,
- whether the analysis is restricted to positive cells,
- whether both ethnicity groups must be observed in a county-quarter,
- and how suppression changes the sample across outcomes.

I strongly recommend a table showing, by ethnicity and outcome:
- total potential county-quarter cells,
- observed cells,
- suppressed/missing cells,
- cells with zero values,
- and cells retained in the regression sample.

Given the likely nonrandom suppression of small Hispanic employment cells, a robustness check on large counties or counties with persistent observability would be helpful.

**Sixth, address seasonality and timing more carefully.**  
H-2A is annual in the paper, while QWI outcomes are quarterly. But agricultural labor demand is highly seasonal. Assigning the same annual treatment to all four quarters likely introduces substantial measurement error and may muddle interpretation of hires and separations. If application dates or start dates are available in the DOL records, even approximately, the paper should use them. If not, at least:
- interact annual H-2A with quarter indicators,
- show whether effects are concentrated in the peak agricultural quarters,
- and be explicit that quarterly estimates are based on an annualized treatment proxy.

This matters particularly for the mechanism claims on hires and separations.

**Seventh, reconsider the placebos and their interpretation.**  
The construction placebo is actually positive and statistically significant, not null. That is informative, but it does not “confirm the null” as stated. It suggests counties with greater H-2A growth may have different Hispanic labor demand dynamics across sectors. The placebo section should be rewritten more carefully. A stronger placebo strategy would include:
- non-agricultural industries with similar Hispanic workforce composition but less exposure to agricultural shocks,
- outcomes for non-Hispanic workers alone,
- and perhaps agriculture-adjacent industries unlikely to use H-2A intensively.

In general, placebos should test the identifying assumptions, not just be deployed as rhetorical support.

**Eighth, strengthen the mechanism analysis or scale it back.**  
The paper infers from lower hires and lower separations in OLS that labor market flows contract rather than workers being actively displaced. But those patterns are also consistent with general local contraction, reporting issues, or composition changes. Since the IV estimates for the mechanisms are not reported, the mechanism discussion is not well supported. Either:
- estimate the mechanism outcomes under the preferred identification strategy, including confidence intervals,
- or present the OLS flow results as descriptive only.

**Ninth, improve the fixed-effects discussion and consider alternative FE structures.**  
The current specification uses county×ethnicity, quarter×ethnicity, and state×quarter FE. That may be reasonable, but the paper should explain why state×quarter is preferred to state×quarter×ethnicity or county×quarter in transformed ratio specifications. It would also help to show robustness to:
- state-specific time trends,
- county-specific linear trends,
- and weighting by baseline agricultural employment.

Because very small counties and very large agricultural counties likely receive equal weight in the baseline, weighted estimates could be informative.

**Tenth, tone down the rhetorical certainty.**  
The title and repeated use of “mirage” are stronger than the evidence currently supports. The paper’s best contribution may be narrower: simple cross-county comparisons overstate displacement, and once one controls more carefully or instruments using baseline exposure, the estimated effect is much smaller and often indistinguishable from zero. That is already interesting. It does not require claiming the policy debate is arguing with “a correlation, not a cause.” In an AER: Insights-style paper, readers will respond better to a precise and disciplined statement of what is identified.

**Finally, some presentational suggestions.**
- Add a county map of H-2A growth and a binned scatter of changes in Hispanic agricultural employment versus H-2A intensity.
- Report coefficient magnitudes in more intuitive units, not only log points.
- Include confidence intervals prominently, especially around the IV null.
- Show heterogeneity by crop intensity or labor-intensive crop counties, as the manifest proposed. If displacement exists anywhere, it is more plausible there.
- Compare results for all workers, Hispanic workers, and non-Hispanic workers separately, not just through interactions.

In sum, I like the question and the data linkage, and I think there is a paper here. But in its current form, the causal argument is not yet persuasive enough to support the strong null conclusion. The paper would improve substantially by extending the H-2A series backward, being transparent about QWI sample construction, and either greatly strengthening or greatly softening the IV-based identification claims.
