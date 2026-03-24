# V1 Empirics Check — openai/gpt-5.4 (Variant C)

**Model:** openai/gpt-5.4
**Variant:** C
**Date:** 2026-03-24T21:44:46.911011

---

## 1. **Idea Fidelity**

The paper pursues an important subset of the manifest, but not the full idea. The manifest proposed a broader design combining two sources of variation—state income tax changes and the 2018 SALT cap—and emphasized estimating the full income-specific migration elasticity gradient using both within-state bracket comparisons and staggered tax reforms. The paper instead narrows almost entirely to the SALT cap. That is a defensible choice for a short AER: Insights-style paper, but it should be presented as such: this is not yet the full “tax flight gradient” project described in the manifest.

Several key elements from the original identification plan are missing or only lightly implemented. First, the state tax-change design is absent, even though it was a central motivation in the manifest and would materially strengthen external validity beyond the one-off TCJA shock. Second, the promised bilateral-flow analysis is not used to sharpen identification or investigate destinations, despite the SOI bilateral files being a major advantage of the data. Third, the “welfare” or fiscal externality calculation is mentioned in the manifest but not delivered here. Finally, the paper claims to estimate the “full income gradient,” but the main triple-difference collapses the top two brackets into “high income” and then presents separate bracket regressions that use a different, weaker specification. So the paper is directionally faithful to the manifest, but it does not yet realize its strongest empirical design.

## 2. **Summary**

This paper uses IRS SOI state-to-state migration data by AGI bracket and exploits the 2018 SALT deduction cap to estimate whether higher-income filers became more likely to leave high-SALT states after TCJA. The headline finding is a monotone income gradient: high-income filers, especially those above \$200,000, exhibit larger post-2018 net outmigration from high-SALT states, with most of the effect coming through higher outflows rather than lower inflows.

The question is important and the data are attractive. But in its current form, the paper does not yet convincingly isolate a tax effect from other post-2018 shocks affecting high-income households in coastal states, and it overstates both the cleanliness of the design and the strength of the substantive conclusion.

## 3. **Essential Points**

1. **Identification is not yet convincing enough for the causal claims being made.**  
   The paper relies on a single national policy change in 2018 that coincides with many other forces affecting high-income households in high-cost coastal states: the broader TCJA package, changes in housing markets, and especially the onset of remote-work migration shortly thereafter. State-by-year fixed effects help, but they do not solve the core problem if these shocks differentially affect high-income brackets within high-SALT states. The paper needs an event-study / dynamic DDD showing parallel pre-trends by bracket and treated status, not just post/pre contrasts. Without that, the main identifying assumption remains asserted rather than demonstrated.

2. **The specifications are inconsistent, and the “gradient” result is weaker than advertised.**  
   The main DDD uses state×bracket, year×bracket, and state×year fixed effects, which is the right saturated structure. But Table 1’s bracket-specific regressions drop to state and year fixed effects only. Those coefficients are therefore not directly comparable to the main estimate and are much more vulnerable to omitted-variable bias. Moreover, the low-income effects are not “small placebo effects”; several are statistically significant and negative. That cuts directly against the mechanism that low-income filers should be minimally exposed to the SALT cap. As written, the monotone gradient is suggestive, but not yet clean evidence of tax-driven heterogeneity.

3. **Inference and magnitudes need more careful treatment.**  
   Clustering at the state level with 51 clusters is not obviously wrong, but with a highly aggregated panel, serial correlation, and a treatment that is effectively a one-time national shock interacting with a small set of treated states, conventional cluster-robust standard errors can overstate precision. At a minimum, I would want wild-cluster bootstrap p-values and preferably randomization/permutation inference based on treatment assignment among states. On magnitudes: a 0.48 percentage-point change in net migration for high-income filers is plausible, but it is modest in headcount terms and may not warrant language like “substantial” or claims that the paper resolves the Young-Varner versus Kleven debate. The paper should translate coefficients into elasticities or implied revenue consequences before making stronger policy claims.

## 4. **Suggestions**

The paper has promise, and I think there is a publishable short paper here if the design is tightened and the claims are narrowed. My main suggestions are as follows.

First, **show the identifying variation directly**. I strongly recommend a figure plotting mean net migration rates by treated vs. control states separately for each AGI bracket, or better, an event-study DDD coefficient path:
\[
1\{t=\tau\}\times \text{HighSALT}_s \times 1\{b = \text{bracket }k\}
\]
with the year before treatment omitted. The paper’s credibility depends on whether high-income migration in high-SALT states was already diverging before 2018. Right now the reader cannot tell. If pre-trends are flat and the break begins in 2018 for upper brackets only, the paper becomes much stronger. If not, that is equally informative and should discipline the claims.

Second, **make the gradient analysis use the same saturated specification as the main DDD**. The separate bracket regressions in Table 1 should include the same state×year fixed effects and exploit within-state, across-bracket contrasts, not simple state and year fixed effects. One straightforward way is to estimate a pooled model interacting Post×HighSALT with the full set of bracket dummies, omitting one middle-income bracket as the reference. That would deliver a coherent set of bracket-specific treatment effects under one common identification strategy. As currently written, the paper mixes two different designs and then interprets them as one unified result.

Third, **deal much more carefully with the low-income “placebo.”** A placebo estimate of 0.0030 for AGI under \$50K that is statistically significant is not reassuring; it is a warning sign. Calling it “small” understates the issue, especially when it is of comparable order to some bracket effects. You should investigate why low-income migration also moves after 2018 in high-SALT states. Possibilities include correlated housing-cost shocks, local labor market changes, or broader urban-to-sunbelt migration trends. One useful exercise would be to redefine the comparison group to brackets with likely minimal itemization but otherwise similar age/life-cycle mobility, or to use narrower bracket interactions rather than grouping everyone under \$50K. At the very least, the placebo needs to be discussed candidly.

Fourth, **tighten the treatment definition and connect it to actual exposure**. “High-SALT state” based on average deductions above \$13,000 is crude. The paper itself argues that exposure is sharply income-specific; the empirical design should reflect that. If possible, construct bracket-specific exposure proxies using pre-TCJA itemization rates and average SALT deductions by income/state from SOI individual statistics. A more compelling treatment would be something like:
\[
\text{PredictedExposure}_{sb} \times \text{Post}_t,
\]
where predicted exposure is high for upper brackets in NY/NJ/CT and low for lower brackets everywhere. That would align the economics and the econometrics much more closely than a binary state indicator crossed with a broad high-income dummy.

Fifth, **be more cautious in the interpretation of economic significance**. The estimated top-bracket effect—roughly 0.39 to 0.48 percentage points—seems plausible, but it is not enormous relative to baseline gross flows of around 3 percent. This is more “detectable but modest” than “large tax flight.” I would encourage you to benchmark the estimate against baseline net migration and against previous papers’ implied elasticities. If the goal is to speak to optimal taxation, convert the reduced-form effect into an elasticity with respect to the after-tax cost of residing in the state, even if only approximately. Without that, it is hard to know whether the estimates are economically large enough to matter for state revenue policy.

Sixth, **improve the discussion of standard errors and finite-sample inference**. With 51 clusters, state clustering is acceptable as a baseline, but not sufficient. Please report wild-cluster bootstrap p-values. Given the small number of treated states and the discrete, one-time treatment onset, a permutation test assigning “high-SALT” status to similarly sized sets of states would also be informative. If the headline result survives these exercises, readers will be much more persuaded.

Seventh, **exploit the bilateral migration files**. This is one of the strongest un-used assets of the project. Where do the high-income outmigrants from high-SALT states go after 2018? If the destinations are disproportionately low-tax states such as Florida, Texas, Tennessee, Nevada, and Arizona, that would materially strengthen the tax interpretation. If instead the pattern is broad-based and not especially tilted toward low-tax destinations, the paper’s tax mechanism becomes less compelling. A destination-side analysis could fit comfortably in an AER: Insights paper as one figure or one short table.

Eighth, **use the state tax changes promised in the manifest as an external validation exercise**, even if not as a full second design. I understand the desire to keep the paper focused, but a short appendix showing that the same upper-income brackets respond more to actual state top-rate changes than middle-income brackets would go a long way. It would show that the SALT result is not peculiar to one federal reform or one set of coastal states. Right now the paper risks being interpreted as a TCJA/coastal-remoteness paper rather than a tax-migration paper.

Ninth, **clean up a few internal inconsistencies and overstatements**. The abstract says “three times the response of filers under \$10,000,” but the text elsewhere emphasizes that low-income effects should be near zero. Those two messages sit uneasily together. Similarly, saying the paper “resolves” the Young-Varner vs. Kleven debate is too strong for one reduced-form design with coarse income bins and no direct elasticity mapping. I would frame the contribution more modestly: the paper provides new evidence that migration responses to tax-related cost shocks are increasing in income in aggregate IRS data.

Finally, **the paper would benefit from a sharper statement of what exactly is being estimated**. Is the object a migration elasticity to taxes, or a reduced-form response to the loss of federal deductibility? Those are not identical. The SALT cap changes the net-of-federal-tax price of state taxes, but also potentially interacts with housing demand, capitalization, and state political expectations. A short conceptual paragraph clarifying the estimand would improve the paper. In particular, if you want to make claims about “state tax competition,” the bridge from SALT deductibility to effective state tax salience and migration choices should be laid out more carefully.

In sum: good question, good data, suggestive patterns, but the current draft is not yet as clean or as definitive as the prose implies. The path forward is clear: align the gradient estimates with the main DDD, show event-study pre-trends, treat the low-income placebo as a serious issue, and strengthen inference. If those pieces fall into place, this could become a strong short paper.
