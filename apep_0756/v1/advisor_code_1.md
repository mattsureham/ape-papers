# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-22T22:16:39.863730

---

**Idea Fidelity**

The paper largely follows the manifest. It uses the staggered city/state adoption of predictive scheduling laws, QWI panel data, and a triple-difference design comparing covered (food and retail) to uncovered industries within treated and untreated counties. The identification strategy, data source, and policy question all align with the original proposal. One noticeable departure is that the paper does not exploit the age heterogeneity (e.g., young workers) mentioned in the manifest, nor does it capitalize on the “access to hours” provision as a separate empirical margin; addressing these would bring the paper closer to the manifest’s full scope.

---

**Summary**

This paper presents the first administrative-data evidence on the labor market effects of predictive scheduling laws, exploiting county-industry-quarter variation in the QWI. A triple-difference estimator comparing covered service industries to uncovered manufacturing/professional industries within treated versus control counties indicates that the scheduling mandates reduce both separations and hires, while employment ticks up slightly and earnings are unchanged. These patterns are interpreted as a “predictability premium”: incumbents gain stability, but the entry pipeline for new workers thins.

---

**Essential Points**

1. **Parallel trends / event-study evidence for the triple difference.** The identifying assumption requires that, in the absence of treatment, the differential between covered and uncovered industries in treated counties would have evolved analogously to that differential in control counties. Currently the paper reports only a single post-treatment coefficient. Please provide event-study coefficients (or other pre-trend diagnostics) for the triple-difference specification to demonstrate that the treatment and comparison margins were on parallel paths prior to the ordinances. Without this, it is difficult to assess whether the point estimates reflect the law or pre-existing differential trends across industries in treated urban counties.

2. **Measurement of treatment exposure in partially treated counties.** Several treated jurisdictions (Seattle/King County, Chicago/Cook County) are counties with substantial areas or workers not covered by the ordinance. The paper notes this and argues it biases toward zero, but the DDD coefficient estimates may still mix treated and untreated populations, raising concerns about differential attenuation or contamination. Please provide either (a) analyses that weight counties by the percent of employment actually exposed (if available), (b) robustness checks at a finer geographic level (e.g., municipal treatment indicator for Seattle/Chicago combined with county administrative data), or (c) decomposition showing how much of the employment mass falls within the treated city versus the residual county area. This will clarify whether the effect sizes capture the targeted policy or a diluted average.

3. **Mechanism for the net employment increase.** The claim that employment rises by 3.1% despite falls in both inflows and outflows hinges on a “retention dividend,” but the arithmetic of flows calls for more evidence. What happens to net employment growth when you compare hires minus separations directly in levels? Is the retention effect concentrated in certain demographics or firm sizes? Moreover, the timing is puzzling given the reduction in new hires: one would typically expect employment to fall unless separations decline even more, yet the flow table is not shown. Please provide additional evidence (e.g., decomposition of employment changes into inflow and outflow components, placebo checks on net flows, or a check that the employment increase is not driven by composition changes) to substantiate the asserted mechanism.

If these concerns cannot be addressed, the paper should be rejected outright because the identification story and interpretation remain ambiguous.

---

**Suggestions**

1. **Event studies and dynamic specification.** In addition to the essential pre-trend test, please report an event-study plot for each main outcome (separation rate, new hire rate, employment) using the triple-difference setup. This will help readers assess dynamic treatment effects, possible anticipation, or delayed responses. If data limitations prevent fine time bins, a handful of leads and lags (e.g., two pre-periods, two post-periods) would still be informative.

2. **Explore age or tenure heterogeneity.** The manifest emphasized that young workers might be most affected. The QWI data allow for age stratification. Even if the main analysis aggregates over ages, a supplementary analysis by age group (e.g., 16–24 vs. older) could illuminate whether the hiring reductions disproportionately affect labor market entrants, which is crucial for the policy interpretation of a “two-tier” market.

3. **Hours and intensity margins.** As noted in the Discussion, QWI lacks hours data. However, the LEHD/processing pipeline sometimes provides average monthly earnings for stable jobs (used already) and, for some states, total wages, which could be used to back out implied hours. If feasible, provide any available proxies (e.g., average earnings per employee) for whether employers also adjust hours. Alternatively, discuss more concretely how the “access to hours” provision might counteract a hiring freeze, perhaps by showing whether average earnings or employment growth differ across part-time–intensive versus full-time–intensive retail establishments (if distinguishable via NAICS subcategories).

4. **Spillovers to uncovered industries.** The triple-difference assumes that uncovered industries within treated counties are unaffected by the scheduling laws. Yet, if large retailers shift operations toward manufacturing or professional services divisions, or if non-covered industries absorb displaced workers, this could contaminate the control group. Consider checking whether manufacturing/professional services outcomes in treated counties change around adoption, even without the triple interaction (e.g., a DD on the “control” industries alone). Alternatively, try other control industries (e.g., logistics) to test sensitivity.

5. **Sample window vis-à-vis later cohorts.** The paper uses data through 2019Q4, yet two cohorts (Philadelphia, Chicago) adopt in 2020. As written, these jurisdictions appear in the “treated county” set but have no post-treatment observations, which may distort the aggregate effect (they contribute only to the pre period). Explicitly clarify how these cohorts enter the estimation (are they included only as pre-period observations?). If they are included, consider dropping them or explaining why their inclusion does not bias the post-treatment effect.

6. **Standard error inference with few clusters.** With only 45 treated counties (and clustering at the county level across ~3,100 clusters), asymptotic inference should be fine, but a wild cluster bootstrap or other small-cluster adjustment focused on the treated set might reassure readers that the standard errors are not understated. If the bootstrap is infeasible, mention any evidence that results are not driven by a few large treated counties (e.g., leave-one-out).

7. **Interpretation of “access to hours” provision.** Since the law explicitly requires offering hours to incumbents before hiring, this provision may be the primary channel through which hires fall. Consider incorporating data or citations that describe how strictly this provision is enforced or whether firms respond by reducing posted hours. At minimum, the Discussion should more carefully distinguish whether the observed decline in hires is due to regulatory compliance costs or to firms optimizing staffing under the new constraints.

8. **Clarify placebo design and interpretation of pure DD.** Table 3 shows that a DD using treated industries only yields zero, and the placebo with manufacturing also yields zero. These are important pieces of evidence. Please expand the text to explain why the DD null arises (because county-level shocks are absorbed), and why the placebo is comforting (it suggests the effect is not driven by a differential shock common to adopting counties). This will help readers appreciate why the triple difference is necessary and why the industry placebo is compelling.

Addressing these suggestions will strengthen the credibility and policy relevance of the manuscript, and help convince readers that predictive scheduling laws truly reshape labor market flows along the lines described.
