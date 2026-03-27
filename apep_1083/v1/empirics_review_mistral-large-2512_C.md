# V1 Empirics Check — mistralai/mistral-large-2512 (Variant C)

**Model:** mistralai/mistral-large-2512
**Variant:** C
**Date:** 2026-03-27T16:20:54.349654

---

### 1. Idea Fidelity

The paper closely adheres to the original idea manifest. It leverages the same data sources (BFS construction investment, ARE housing inventory), exploits the same identification strategy (continuous DiD with exposure intensity, RDD at the 20% threshold), and directly tests the core research question: whether the Second Home Initiative caused sectoral reallocation or a broad investment freeze. The manifest’s emphasis on the surprise nature of the vote, the sectoral decomposition, and the alpine vs. non-alpine heterogeneity is all preserved. The paper even retains the "smoke test" evidence from Davos and Winterthur as motivating examples.

One minor deviation is the manifest’s suggestion of a complementary RDD, which the paper includes but downplays due to limited power. This is reasonable given the data constraints. The paper also expands the scope by adding a placebo test (road infrastructure) and a standardized effect size appendix, which strengthen the analysis without straying from the original idea.

### 2. Summary

This paper uses 30 years of municipality-level construction investment data to evaluate the causal effect of Switzerland’s 2012 Second Home Initiative, which banned new second-home construction in municipalities exceeding a 20% second-home share. Contrary to the reallocation hypothesis, the ban reduced residential investment by 15% and commercial investment by 35%, with no evidence of capital flowing into unrestricted sectors. The investment freeze is concentrated in alpine municipalities, suggesting a local construction ecosystem collapse rather than substitution. The results challenge the theoretical justification for sectoral construction bans globally.

---

### 3. Essential Points

**1. Pre-trends and parallel trends assumption**
The paper acknowledges a marginally significant pre-trend test ($p = 0.023$) even with canton × year fixed effects. This is a critical threat to identification. The authors should:
- Show the event study coefficients graphically (not just describe them) to assess whether the pre-trends are economically meaningful or just noisy.
- Report the joint F-test *without* canton × year fixed effects to demonstrate how much the specification improves parallel trends.
- Consider a more flexible specification (e.g., municipality-specific linear trends) to absorb residual differential trends. If the results hold, this would strengthen confidence in the findings.

**2. Treatment assignment timing and measurement error**
The ARE housing inventory is only available from 2017, but treatment status is assigned based on post-implementation data. Municipalities near the 20% threshold may have been misclassified if their second-home shares changed between 2012 and 2017. The authors should:
- Validate the 2017 treatment assignment against earlier data (e.g., 2013 or 2014 inventories) if available, or at least discuss the potential for measurement error.
- Conduct a sensitivity analysis restricting the sample to municipalities far from the 20% threshold (e.g., >25% or <15%) to assess whether misclassification drives the results.

**3. Extensive margin effects and the IHS transformation**
The IHS transformation ($\log(Y + 1)$) may not fully account for municipalities transitioning from positive to zero investment. The authors should:
- Report the share of municipalities with zero investment pre- and post-treatment by sector to assess the importance of the extensive margin.
- Consider an alternative specification (e.g., Poisson pseudo-maximum likelihood or a two-part model) to handle zeros more flexibly. If the results are robust, this would address concerns about the transformation’s adequacy.

---

### 4. Suggestions

**A. Strengthening the identification**
1. **Alternative control groups**: The paper uses all municipalities below 20% as controls, but many of these are urban or suburban and may not be comparable to alpine treated municipalities. Consider:
   - A matched control group (e.g., propensity score matching on pre-trends, population, and geography).
   - A synthetic control approach for the most-affected municipalities (e.g., Davos, Zermatt).
   - A triple-difference design (alpine × treated × post) to further isolate the alpine-specific effect.

2. **Dynamic effects**: The event study coefficients (Equation 3) should be plotted to show the timing of the effect. This would help distinguish between:
   - An immediate freeze (consistent with the ecosystem channel).
   - A gradual decline (consistent with anticipation or delayed implementation).
   - A temporary dip followed by recovery (which would weaken the paper’s conclusions).

3. **Placebo tests**: The road infrastructure placebo is a strength, but additional placebos would help:
   - Public construction investment (e.g., schools, hospitals), which should not be affected by a private residential ban.
   - Construction investment in neighboring untreated municipalities (to test for spillovers).

**B. Improving the economic interpretation**
1. **Magnitudes**: The paper reports log-point changes but could better contextualize the economic significance:
   - Convert the log-point estimates to percentage changes and CHF amounts for the average treated municipality (e.g., "a 35% decline in commercial investment corresponds to CHF X per municipality-year").
   - Aggregate the effects across all treated municipalities and years to show the total foregone investment (e.g., "the ban destroyed CHF Y billion in commercial investment over 2013–2023").
   - Compare the commercial investment decline to the residential decline in CHF terms to emphasize the asymmetry.

2. **Mechanism evidence**: The "construction ecosystem" channel is plausible but could be tested more directly:
   - Use firm-level data (e.g., BFS business statistics) to show whether construction firms in treated municipalities exited or downsized post-2012.
   - Test whether the effect is larger in municipalities with fewer construction firms (more specialized ecosystems) or more firms (more resilient ecosystems).
   - Examine whether the effect is attenuated in municipalities with pre-existing commercial construction (e.g., those with hotels or conference centers).

3. **Heterogeneity**: The alpine vs. non-alpine split is compelling but could be refined:
   - Test whether the effect varies with the *distance* to the 20% threshold (e.g., municipalities at 50% vs. 22%).
   - Examine heterogeneity by municipality size or pre-existing commercial investment levels.
   - Test whether the effect is larger in municipalities with more second-home construction *as a share of total construction* (i.e., more dependent on the banned activity).

**C. Addressing potential confounders**
1. **Financial crisis and tourism demand**: The 2008 financial crisis and post-2012 tourism trends could confound the results. The canton × year fixed effects should absorb most of this, but the authors could:
   - Include canton-specific linear trends to further control for differential recovery from the crisis.
   - Test whether the effect is robust to excluding 2008–2010 (the crisis years) from the pre-period.

2. **Other policies**: The paper mentions the Zweitwohnungsgesetz (ZWG) entering force in 2016. This could have intensified the effect, but the authors do not discuss it. They should:
   - Test whether the effect grows larger after 2016 (e.g., by interacting treatment with a post-2016 indicator).
   - Discuss whether the ZWG’s implementation could have caused anticipation effects post-2012.

3. **Municipal mergers**: The paper notes that the merge rate is lower than the raw municipality count due to boundary changes. The authors should:
   - Confirm that the results are robust to excluding municipalities affected by mergers.
   - Discuss whether mergers could differentially affect treated vs. control municipalities (e.g., if treated municipalities were more likely to merge post-2012).

**D. Presentation and robustness**
1. **Tables and figures**:
   - The main results table (Table 1) should include the number of treated and control municipalities in each panel.
   - The heterogeneity table (Table 2) should use the same specification as the main results (canton × year fixed effects) for consistency.
   - Add a figure showing the distribution of second-home shares to illustrate the treatment assignment.

2. **Robustness checks**:
   - Report results with and without the IHS transformation to show its impact.
   - Test whether the results hold for the *level* of investment (not log-transformed) to assess sensitivity to functional form.
   - Include a specification with municipality-specific linear trends to address pre-trends.

3. **Standard errors**:
   - The paper clusters standard errors at the municipality level, which is appropriate. However, with only 325 treated municipalities, the effective number of clusters may be small. The authors should:
     - Report wild bootstrap p-values (e.g., Cameron et al., 2008) for the main results to assess sensitivity to cluster-robust inference.
     - Consider multiway clustering (e.g., municipality and canton) if there are concerns about spatial correlation.

**E. Policy implications**
1. **Global relevance**: The paper argues that the results challenge the reallocation hypothesis for construction bans globally. To strengthen this claim:
   - Discuss whether the Swiss context (e.g., specialized alpine economies, direct democracy) limits external validity.
   - Compare the Swiss ban to other policies (e.g., Barcelona’s tourist apartment limits) to assess whether the mechanisms are likely to generalize.

2. **Welfare analysis**: The paper stops short of a full welfare analysis, but it could:
   - Estimate the effect on housing prices (using Hilber & Schoni, 2020) and combine this with the investment effects to discuss net welfare impacts.
   - Discuss the distributional consequences (e.g., winners: existing homeowners; losers: construction workers, local businesses).

3. **Alternative policies**: The paper could briefly discuss alternative policies that might achieve the same goals (e.g., limiting second homes) without freezing investment, such as:
   - Taxes on second homes (e.g., higher property taxes for non-primary residences).
   - Zoning reforms that allow more commercial development in exchange for second-home restrictions.

---

### Final Assessment

This is a strong paper with a clear, policy-relevant research question and a well-executed empirical strategy. The results are economically meaningful and challenge a key justification for construction bans. The authors have anticipated many potential concerns (e.g., placebo tests, RDD, heterogeneity) and addressed them thoughtfully. With the suggested improvements—particularly around pre-trends, treatment assignment, and mechanism evidence—the paper could be even more compelling. The current version is publishable in a good field journal, but addressing the essential points would make it suitable for a top general-interest journal.
