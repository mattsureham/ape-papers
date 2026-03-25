# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-25T13:04:59.894327

---

**Idea Fidelity**

The paper hews closely to the idea manifest. It studies the staggered legalization of alkaline hydrolysis (AH) across U.S. states, uses BLS QCEW data for NAICS 812210 (with adjunct checks on 812220), and applies a Callaway–Sant’Anna DiD setup to infer causal effects on the funeral services industry. The manuscript preserves the original policy variation, data sources, and treatment timing described in the manifest. It also addresses the core research question: does legalizing a cheaper disposition technology dissolve incumbent monopoly rents? While the manifest envisioned heterogeneity decompositions and welfare implications, the paper delivers the proposed mechanism checks (e.g., substitution away from crematories, state-size heterogeneity) but stops short of a direct consumer surplus calculation—the welfare discussion remains qualitative. That said, the empirical strategy and emphasis on competitive effects versus market expansion remain faithful to the initial idea.

---

**Summary**

This paper uses staggered difference-in-differences (Callaway–Sant’Anna) to estimate the effects of state-level legalization of alkaline hydrolysis on the U.S. funeral services industry. Leveraging the 2017–2023 cohort variation and QCEW data for NAICS 812210, the author finds that legalization increases funeral home establishments and employment without reducing wages, while adjacent crematory activity remains unchanged. The results are interpreted as evidence that AH expands the market rather than compressing incumbent margins, due to behavioral frictions and product differentiation.

---

**Essential Points**

1. **Interpretation of the “market expansion” mechanism remains speculative without direct evidence.** The main empirical findings are consistent with both market expansion and incumbent adjustment (e.g., incumbents adding AH services). However, the paper does not exploit any within-industry variation that could distinguish these channels—such as firm-level entry versus incumbents adding AH, or any pricing data. Without such evidence, it is difficult to rule out alternative stories (e.g., increases in employment reflect incumbents hiring to provide AH, in which case the industry could still be capturing surplus). The customer-base expansion story needs more empirical grounding.

2. **Pre-trend violations in wages undermine the credibility of wage effects.** The event study shows statistically significant negative wage trends two and four years before treatment, raising questions about the wage specification. The paper acknowledges this but continues to interpret the post-treatment wage rise as meaningful. Given these pre-trends, the paper should either adjust the specification (e.g., flexible trends, trimming cohorts with trends) or refrain from making claims about wages.

3. **Identification assumptions deserve more scrutiny, particularly given the exclusion of “always treated” states.** By removing states that legalized before 2014, the analysis restricts attention to later adopters. Yet the sample still includes only 10 cohort states and 28 never-treated states, raising concerns about heterogeneity driving results. The paper’s parallel trends claims rest on relatively short pre-periods for some cohorts. Moreover, the argument that legalization is exogenous to industry performance is asserted but not empirically supported (e.g., no placebo tests or rejection of pre-trend differences in funeral industry growth rates). Stronger diagnostic evidence is needed to bolster credibility.

If additional essential issues exist beyond these three, I would lean toward rejection until they are resolved, given their bearing on causal claims.

---

**Suggestions**

1. **Strengthen the mechanism tests to differentiate between new entrants versus incumbent expansion.** Since NAICS 812210 aggregates funeral homes regardless of technology, the paper could consider:
   - Exploiting firm-level data from state licensing (if available) to identify new AH-certified providers versus existing firms adding the service.
   - Using alternative administrative data (e.g., business registrations, occupational licenses) to count entities explicitly advertising AH.
   - Conducting text-based analyses of funeral home websites (perhaps via web scrapes) to see if incumbents quickly adopt AH post-legalization, which would support the incumbent expansion hypothesis.
   - Interviewing industry associations or using trade publications to gauge whether AH legalization led to new firms or service diversification.

   These additions would transform the “expansion versus competition” narrative from conjecture to evidence.

2. **Address wage pre-trends more thoroughly.** The negative pre-treatment wage coefficients suggest the wage series may violate parallel trends. Consider:
   - Estimating specifications with unit-specific linear time trends to absorb differential secular movements in wages.
   - Dropping early cohorts with stronger pre-trends and showing robustness.
   - Restricting attention to a narrower set of states with stable pre-trends.
   - Running placebo DiDs (e.g., assigning fake treatment years) to ensure wage patterns do not arise absent legalization.

   If pre-trends persist, the discussion should clearly state that wage estimates are uninterpretable, rather than suggestive of no hurt to incumbents.

3. **Provide more diagnostic evidence for parallel trends and exogeneity.** To increase confidence in identification:
   - Plot aggregated trajectories of outcomes for treated versus never-treated states (possibly with normalized indices) to visually assess trends beyond the aggregated event study.
   - Conduct placebo “treatment” assignments to never-treated states and show null effects.
   - Explore whether any state-level covariates (e.g., demographic changes, regulatory shocks) correlate with legalization timing; if so, control for them or show they do not bias results.
   - Use synthetic control or matrix completion as robustness checks for the main outcome, especially for large states like California which drive results.

4. **Consider heterogeneity beyond state size.** The paper hints that large states drive the establishment effects. To understand the generalizability:
   - Interact the treatment indicator with measures of urbanization, density, or existing cremation rates to see where AH is most “viable.”
   - Assess whether states with higher environmental preference proxies (e.g., green voting share) exhibit stronger responses, supporting the idea of distinct consumer preferences.
   - Examine whether treated states with stronger regulatory hurdles (e.g., licensing requirements) exhibit delayed entry, as the event study slopes might suggest.

5. **Enhance the welfare discussion with back-of-the-envelope calculations.** Because the motivation emphasizes welfare gains from cheaper AH, the paper would benefit from numerical illustrations:
   - Use available price differentials ($2,500 vs. $6,280 vs. $8,300) and treatment effects on employment to infer potential consumer surplus gains or cost savings.
   - Even if direct price data are unavailable, survey or newspaper reports could provide ranges for AH uptake, allowing for conservative welfare bounds.
   - Alternatively, leverage cremation vs. burial substitution rates from secondary sources to argue about the share of the market that could plausibly adopt AH.

6. **Clarify the role of never-treated states in the Callaway–Sant’Anna design.** The paper presents both not-yet-treated and never-treated control specifications but does not discuss whether the results are sensitive to the choice. It would be helpful to:
   - Show ATT estimates using never-treated controls for all outcomes (not just establishments).
   - Discuss the pace of treatment adoption—if control states later adopt AH beyond 2023, the “never-treated” group shrinks; the paper should mention how future adoption might affect inference.
   - Compare the characteristics of never-treated states (e.g., population, funeral industry size) to treated states to reassure readers that the control group is balanced.

7. **Expand the discussion of limitations and future research.** The conclusion mentions the lack of price data but could more explicitly acknowledge that the increase in establishments might reflect multi-tasking incumbents rather than net market expansion. Suggest directions for future work:
   - Collect primary data (surveys, interviews) on AH adoption by funeral homes.
   - Study consumer awareness and attitudes toward AH over time to see if demand is increasing independently of legalization.
   - Examine environmental externalities as an additional welfare channel.

Finally, include a more detailed appendix describing the cohort sample construction (e.g., list of states per cohort, exact date of legalization) and the migration of states between groups (treated, never-treated). This transparency will help other researchers replicate or extend the study.

---

Overall, the paper makes an intriguing contribution by examining a novel deregulation case, but it would benefit from deeper mechanism analysis, more robust treatment of pre-trends, and clearer backstopping of causal claims.
