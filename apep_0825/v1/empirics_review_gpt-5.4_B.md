# V1 Empirics Check — openai/gpt-5.4 (Variant B)

**Model:** openai/gpt-5.4
**Variant:** B
**Date:** 2026-03-23T14:49:25.935805

---

## 1. Idea Fidelity

The paper is broadly faithful to the manifest’s substantive question: it studies Sweden’s 2016 Settlement Act, municipality-level SD vote changes, and county-level SCI network exposure. It also keeps the intended two-channel structure of “own exposure” versus “network exposure” and uses the 2010–2014 period as a placebo.

However, it departs from the core identification strategy in an important way. The manifest proposed using the policy-induced refugee quota shock as the treatment, and the SCI-weighted exposure as a Bartik-style instrument built from that quasi-experimental policy allocation. The paper instead uses **realized changes in non-EU foreign-born shares from 2014–2017**, which are plausibly endogenous to local conditions and subsequent mobility, rather than the actual Bosättningslagen quota assignment. As written, this is not the clean policy-shock design promised in the manifest, and it substantially weakens the causal interpretation. The paper also describes SCI as part of a “shift-share instrument,” but in the empirical sections network exposure is simply entered as a regressor, not used as an instrument in a clearly defined IV strategy.

## 2. Summary

This paper asks whether Sweden Democrats’ gains after Sweden’s 2016 mandatory refugee dispersal law spread through social networks, not only through local refugee exposure. Using municipality-level election outcomes and county-level Facebook Social Connectedness Index links, it finds that SCI-weighted exposure to refugee inflows in socially connected counties predicts larger SD gains in 2018, but that this association reverses by 2022.

The topic is timely and potentially interesting, and Sweden provides a valuable institutional setting. But in its current form the paper does not convincingly identify a causal network effect of the policy, because the treatment is not the policy allocation itself and the network regressor is likely contaminated by omitted regional shocks and mechanical aggregation issues.

## 3. Essential Points

1. **The paper does not use the policy shock it claims to exploit.**  
   The central problem is that “treatment” is measured as the realized change in non-EU foreign-born share from 2014 to 2017, not the Bosättningslagen quota or some close administrative measure of assigned placements. Realized foreign-born growth can reflect endogenous secondary migration, local labor demand, housing supply, prior settlement patterns, and municipal responses. This makes both own exposure and network exposure difficult to interpret causally. To support the paper’s main claim, the authors need to use the actual municipality quota/allocation data induced by the law, or at minimum show very convincingly that realized 2014–2017 changes are a strong and unbiased proxy for assigned settlement.

2. **The “network effect” is not separately identified from county-level confounders.**  
   Network exposure is defined at the county level and then assigned to every municipality in the county. With only about 21 counties, the effective variation for the key regressor is county-level, while the outcome is municipality-level. This creates a serious Moulton-type problem and raises concern that the coefficient reflects unobserved county-level political, media, or economic shocks correlated with both SCI links and SD growth. The placebo helps little because one pre-period cannot rule out differential post-2015 shocks. The paper needs a more persuasive design for separating social-network spillovers from correlated regional trends—e.g., richer pre-trend evidence, alternative geographic/spatial controls, leave-neighbor-out structures, or county-level analysis that is honest about the level of identifying variation.

3. **The interpretation of the 2022 reversal is overstated.**  
   The sign flip is interesting, but the paper currently interprets it as evidence that “experience moderates contagion.” That is speculative. Between 2018 and 2022, SD’s national rise reflected many forces unrelated to the 2016 settlement reform, including crime salience, coalition dynamics, and national campaigning. Without a clearer dynamic design tying the 2022 outcome to the original treatment intensity, the “reversal” result is descriptive rather than a clean causal test of fading contagion. The conclusion should be substantially softened unless the authors can rule out alternative explanations.

## 4. Suggestions

I think the paper has the seed of a good short paper, but it needs to become much more disciplined about what is identified and what is not.

First, I strongly encourage the authors to **rebuild the treatment around administrative allocation data**. The paper repeatedly invokes the Bosättningslagen as generating quasi-experimental variation, yet the empirical work substitutes in realized changes in non-EU foreign-born shares. That substitution matters a lot. If municipality-level assigned quotas or placements under the law exist, those should be the core treatment. If only county-level quotas are available, then the paper should either aggregate the analysis to county level or transparently discuss the limitations of municipality-level implementation. If administrative quota data are unavailable, the paper should stop describing the design as quasi-experimental in the strong sense and instead present the analysis as evidence on correlates of backlash after the reform.

Second, the paper would benefit from a clearer distinction between **policy exposure, realized demographic change, and network transmission**. Right now these concepts are blurred. A stronger setup would be: (i) assigned refugee intake under the law as the exogenous shock; (ii) realized demographic change as a possible first-stage or mediating outcome; and (iii) SCI-weighted assigned intake in other counties as the spillover channel. This would make the paper much easier to evaluate and would align it more closely with the original idea.

Third, I recommend being much more explicit about the **level of identifying variation**. Because network exposure varies only at the county level, the effective number of independent observations for the key regressor is small. The municipality-level sample size of 283 may be misleading. The paper should report a county-level scatter plot of residualized outcomes against residualized network exposure, show leverage diagnostics, and discuss whether the results are driven by a few counties (for example, Skåne or Stockholm-related observations). A leave-one-county-out exercise would be especially useful. If the result disappears when one or two counties are removed, readers should know that.

Relatedly, the current standard-error discussion understates the concern. Wild cluster bootstrap is helpful, but it does not solve the underlying issue that the key regressor is measured at a much higher level than the outcome. I would suggest either (a) estimating the main network specification at the county level, where the treatment actually varies, or (b) keeping the municipality-level specification but being explicit that precision is ultimately based on around 20 county clusters and should be interpreted cautiously. AER: Insights readers will immediately notice this issue.

Fourth, the paper needs substantially stronger evidence against the claim that SCI exposure is proxying for **geographic or regional similarity** rather than social ties. The current placebo with only 2010–2014 is not enough. Some constructive additions:
- Control flexibly for geographic distance to high-exposure counties.
- Include adjacency-based exposure alongside SCI exposure, to ask whether SCI adds explanatory power beyond simple spatial spillovers.
- Compare SCI links to inverse-distance weights or same-media-market weights if feasible.
- Show that results are not driven by southern Sweden or by nearby counties only.
- If possible, decompose SCI exposure into near and far ties; a stronger effect for distant but socially connected counties would be much more consistent with a social-network channel.

Fifth, I would encourage the authors to present the empirical design in a more restrained way. The paper refers to the SCI measure as a “shift-share instrument,” but no actual IV estimand is presented. That wording should be revised unless the authors implement a real instrumental variables strategy with a clearly stated exclusion restriction and first stage. As it stands, the paper estimates reduced-form associations using a network-weighted treatment regressor. That can still be interesting, but the terminology should match the econometrics.

Sixth, some **basic descriptive validation** would strengthen credibility:
- Show the distribution of the treatment and network exposure, ideally with maps.
- Report how the 7 missing municipalities arise and whether missingness is systematic.
- Clarify whether the election data source is SCB table ME0104T3 or ME0104T4; the text and manifest do not fully line up.
- Document exactly how municipalities are mapped to counties and whether any municipal boundary changes matter.
- Show the correlation between assigned quotas (if available), realized non-EU foreign-born changes, and baseline municipality characteristics.

Seventh, the own-exposure results are internally a bit unstable, and that deserves discussion rather than spin. In Table 1, the own effect is not robustly significant under clustered inference; in Table 2 it becomes significant once network exposure is added. This could reflect omitted-variable bias, but it could also reflect multicollinearity or mechanical features of the constructed network regressor. I would suggest reporting variance inflation factors, the treatment-network correlation more fully, and perhaps partial-residual plots. A short paper can absolutely report this pattern, but it should not over-interpret it as evidence that “the true channel operates through networks” without stronger support.

Eighth, I would scale back the rhetoric around the **2022 reversal** unless the authors can do more. One useful way forward would be an event-style decomposition: estimate 2010–2014, 2014–2018, and 2018–2022 changes in a unified framework, or use party vote levels with election fixed effects interacted with treatment intensity. Another would be to examine whether places with high 2016 policy exposure had differential changes in intermediate outcomes by 2022. Without that, the current interpretation is too behavioral and not sufficiently tied to the design.

Finally, I think the paper would improve by narrowing its claim. There may be a publishable descriptive result here: municipalities in counties socially connected to high-refugee-intake counties saw larger SD gains in 2018, controlling for own demographic change. That is interesting. But a claim about the **causal network propagation of policy backlash** requires a cleaner treatment measure and stronger exclusion arguments than the current draft provides.

Overall, the question is promising and the Swedish setting is attractive, but the paper in its current form does not yet establish the causal contribution it aims to make. A revision centered on actual policy allocations, more honest treatment of the level of variation, and stronger tests against regional confounding could materially improve it.
