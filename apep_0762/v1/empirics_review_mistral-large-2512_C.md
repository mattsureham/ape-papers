# V1 Empirics Check — mistralai/mistral-large-2512 (Variant C)

**Model:** mistralai/mistral-large-2512
**Variant:** C
**Date:** 2026-03-22T23:02:02.976744

---

### 1. Idea Fidelity

The paper adheres closely to the original manifest. It exploits the staggered adoption of Dark Sky Community designations (29 US communities, 2001–2023) to estimate the causal effect of light pollution regulation on property values, using Zillow ZHVI data and the Callaway-Sant’Anna (2021) estimator. The manifest’s key elements—identification strategy (staggered DiD with matched controls), data sources (Zillow, VIIRS, CDC PLACES), and research question (amenity value of darkness)—are all faithfully executed.

Two minor deviations:
- The manifest mentions VIIRS radiance as a "first stage" to verify ordinances reduce light, but the paper does not report this analysis. This is a missed opportunity to validate the treatment’s biological plausibility.
- The manifest frames the paper as testing whether darkness is capitalized *positively* into property values, but the paper’s central finding is a *negative* effect. This pivot is justified by the data but could be flagged more explicitly in the abstract/introduction.

### 2. Summary

The paper provides the first causal estimate of the economic value of darkness by studying the staggered adoption of Dark Sky Community certifications across 29 US communities. Using a staggered difference-in-differences design with matched controls, it finds that certification—requiring enforceable outdoor lighting ordinances—*reduces* home values by 4–7%, with a preferred estimate of −6.5% (SE = 3.9%). The result is robust to alternative specifications and suggests that compliance costs (fixture replacement, luminance limits) outweigh any amenity gains from reduced light pollution for most communities. Heterogeneity analysis reveals a positive effect only in Flagstaff, where astronomical heritage likely creates pre-existing demand for darkness.

### 3. Essential Points

**1. Magnitude and Plausibility of the Effect**
The estimated −6.5% effect is large relative to the literature on environmental amenities. For context:
- Chay and Greenstone (2005) find a 2–3% increase in property values from air quality improvements.
- Greenstone and Gallagher (2008) estimate an 18–24% increase from Superfund cleanup.
- The paper’s effect is comparable in absolute magnitude but opposite in sign, which is surprising given that light pollution is a salient and growing concern.

*Critical issue*: The paper does not adequately address whether the magnitude is plausible. Key questions:
- Are compliance costs large enough to explain a 6.5% decline? The paper cites \$1–5M for a small city’s retrofitting (Gallaway 2010), but this is aggregate, not per-home. For a community of 5,000 homes, \$5M implies \$1,000 per home—far below the \$17,700 implied by the 6.5% effect. The authors must reconcile this discrepancy or revise the interpretation.
- Is the effect driven by general equilibrium adjustments (e.g., reduced commercial activity) rather than direct compliance costs? The paper mentions "reduced nighttime visibility" and "commercial signage restrictions" but does not quantify their contribution.

**2. Standard Errors and Statistical Power**
The paper reports a p-value of 0.076 for the TWFE estimate (−4.1%, SE = 2.3%) and a randomization inference p-value of 0.541, suggesting that conventional clustered standard errors may overstate precision. With only 32 treated zip codes, the study is underpowered to detect effects smaller than ~5–6%.

*Critical issue*: The authors should:
- Report power calculations to clarify the minimum detectable effect (MDE) given the sample size. If the MDE is larger than the effect size, the paper cannot rule out economically meaningful positive effects.
- Avoid overinterpreting the "precise negative effect" narrative. The randomization inference result suggests the effect is not statistically distinguishable from zero at conventional levels. The contribution is the *sign* and *bound* of the effect, not its precision.

**3. Heterogeneity and External Validity**
The heterogeneity analysis (Table 4) reveals stark differences across cohorts, with Flagstaff showing a +14.6% effect and most others showing negative effects. The paper attributes this to Flagstaff’s "astronomical heritage," but this explanation is post hoc and not tested formally.

*Critical issue*: The authors must:
- Test whether heterogeneity is systematically related to observable characteristics (e.g., pre-treatment light pollution levels, tourism dependence, or astronomical infrastructure). A simple regression of cohort-specific ATTs on these variables would strengthen the argument.
- Address external validity: Are the 29 treated communities representative of US municipalities? The paper notes that communities self-select into certification, but it does not discuss whether the sample is skewed toward small, rural, or tourism-dependent towns. If so, the results may not generalize to larger cities where compliance costs or amenity values differ.

### 4. Suggestions

**A. Strengthen the First Stage**
The manifest promises a "first stage" using VIIRS radiance to verify that ordinances reduce light pollution, but this analysis is missing from the paper. The authors should:
- Report the effect of certification on VIIRS radiance (annual, 2012–2024) using the same staggered DiD design. This would validate that the treatment has the intended biological effect.
- Test whether the magnitude of radiance reduction correlates with the property value effect. If darker communities see larger declines in home values, this would support the compliance cost mechanism.

**B. Improve the Cost-Benefit Interpretation**
The paper attributes the negative effect to compliance costs but does not quantify them. Suggestions:
- Estimate the per-home compliance cost using data on fixture replacement costs, municipal retrofitting budgets, or survey evidence from certified communities. Compare this to the \$17,700 implied by the 6.5% effect.
- Conduct a back-of-the-envelope cost-benefit analysis. For example, if the average homeowner spends \$1,000 on compliance, the net effect is −6.5% + (amenity value of darkness). The paper could bound the amenity value by assuming the net effect is non-positive (i.e., amenity value ≤ \$1,000 per home).
- Discuss whether energy savings from shielded fixtures (cited as 30–60%) could offset compliance costs. If so, why don’t homeowners value these savings?

**C. Address Alternative Mechanisms**
The paper focuses on compliance costs but mentions other potential mechanisms (reduced safety, commercial vitality). To rule these out:
- Test whether the effect is larger in commercial-heavy zip codes (using Census data on employment composition). If the effect is driven by reduced commercial activity, it should be concentrated in areas with more businesses.
- Use CDC PLACES sleep data (mentioned in the manifest) to test whether certification improves sleep outcomes. If sleep improves but property values fall, this would support the compliance cost mechanism over a "darkness is bad" story.

**D. Refine the Heterogeneity Analysis**
The heterogeneity across cohorts is the paper’s most interesting finding. To make it more rigorous:
- Regress cohort-specific ATTs on pre-treatment characteristics (e.g., baseline VIIRS radiance, population, tourism employment, presence of observatories). This would test whether the Flagstaff effect is driven by astronomical infrastructure or other factors.
- Report event studies for Flagstaff vs. other cohorts separately. If Flagstaff’s pre-trends are flat but its post-trends are positive, this would strengthen the causal interpretation.

**E. Clarify the Policy Implications**
The paper’s conclusion—that darkness is not a priced amenity—has important policy implications. To sharpen these:
- Compare the property value effect to estimates of non-market damages (e.g., health costs from melatonin disruption, ecological harm). If the non-market damages exceed the compliance costs, the case for regulation remains strong even if property values fall.
- Discuss whether the results generalize to other forms of light pollution regulation (e.g., EU’s "Toward Zero Pollution" strategy, US LED streetlight conversions). The Dark Sky ordinances are unusually strict (e.g., 3,000K color temperature limits), so weaker regulations might have smaller effects.

**F. Minor Suggestions**
- The abstract and introduction frame the paper as testing whether darkness is capitalized *positively*, but the result is negative. Revise the framing to emphasize the surprise of the finding (e.g., "Contrary to the literature on noise and air pollution, I find that...").
- The event study (Table 3) shows a pre-trend at t−3 (0.033, p < 0.05). While the authors note this is "well within the range of post-treatment effects," it is the largest pre-trend and warrants discussion. Is this driven by a specific cohort (e.g., Flagstaff)?
- The robustness table (Table 5) omits the randomization inference p-value for the CS-DiD estimate. Report this to clarify the precision of the main result.
- The standardized effect size (Table A1) is labeled "Moderate negative," but the SDE of −0.12 is closer to the "Large" threshold (|SDE| > 0.15). Reclassify or justify the label.

### Final Assessment
This is a well-executed paper that fills a critical gap in the literature. The identification strategy is sound, the data are appropriate, and the result is economically meaningful. However, the magnitude of the effect is large relative to compliance costs, and the statistical power is limited. The authors must address these issues to strengthen the paper’s credibility. With revisions—particularly to the cost-benefit interpretation and heterogeneity analysis—this could be a strong contribution to *AER: Insights*.
