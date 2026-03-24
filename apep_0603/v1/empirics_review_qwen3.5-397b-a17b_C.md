# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant C)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** C
**Date:** 2026-03-12T16:23:32.507319

---

# Review: "Checks to Shops: The Local Fiscal Multiplier of Poland's Family 500+ Program"

## 1. Idea Fidelity

The paper largely pursues the original manifest but with several notable deviations that weaken identification:

**Adhered to:**
- Core research question (local fiscal multiplier of 500+)
- Data source (GUS BDL API, powiat-level)
- Two-phase design exploiting 2016 launch and 2019 universalization
- Primary outcomes (business registrations, unemployment, births)

**Deviations from Manifest:**
- **Treatment construction:** The manifest proposed a proper Bartik instrument (Share_i × National_Shock_t), but the paper uses pre-program birth rates as a proxy for treatment intensity. This is not a Bartik design—it's a continuous DiD with a potentially endogenous intensity measure.
- **Aggregation level:** The manifest confirmed gmina-level data availability (4,198 units) but the paper aggregates to powiat level (380 units), losing substantial variation and statistical power.
- **Mechanism tests:** The manifest proposed interacting treatment with pre-program median income and examining sector-specific employment. The paper does heterogeneity by income proxy but lacks the sectoral breakdown and MPC channel tests outlined.
- **Fiscal multiplier:** The manifest promised an actual multiplier estimate (Δactivity per złoty transferred). The paper reports reduced-form coefficients but never calculates a proper multiplier.

## 2. Summary

This paper estimates the local economic effects of Poland's Family 500+ cash transfer program using geographic variation in pre-program birth rates across 380 powiats. The main finding is that higher treatment intensity increased new business registrations by approximately 1.9 per 10,000 population, concentrated in higher-income districts. The paper contributes to the fiscal multiplier literature by examining a permanent monthly transfer rather than one-off stimulus, and by documenting an entrepreneurial margin of response.

## 3. Essential Points

**Three critical issues must be addressed before this paper can support its claims:**

1. **Treatment Intensity is Not Exogenous:** Using pre-program birth rates as a proxy for 500+ transfer intensity conflates fertility with fiscal exposure. High birth-rate powiats differ systematically from low birth-rate powiats (rural east vs. urban west, different economic trajectories, different EU fund exposure). The significant pre-period coefficients acknowledged in the baseline event study (and the significant birth-rate placebo at p=0.024) suggest parallel trends fail. The voivodeship-year FE helps but cannot fully absorb powiat-specific trends correlated with historical fertility patterns. **Required:** Either (a) construct a proper Bartik instrument using actual household composition data from the 2011 census interacted with national eligibility rules, or (b) present this as a reduced-form association with much more cautious causal language.

2. **No Actual Fiscal Multiplier is Estimated:** The title and abstract claim to estimate a "local fiscal multiplier," but the paper never calculates Δlocal activity / Δtransfers. The back-of-the-envelope calculation (29 firms per PLN million) is not a multiplier—a fiscal multiplier requires comparable units (e.g., PLN of output per PLN of spending). Without powiat-level GDP or income data, this claim is unsupported. **Required:** Either obtain powiat-level GDP proxies (e.g., tax revenue, wage bills from REGON) and calculate an actual multiplier, or retitle the paper to reflect that this estimates local economic *effects* rather than a *multiplier*.

3. **The High-Income Heterogeneity Contradicts the Identification Story:** If the identifying variation comes from rural, high-fertility eastern Poland receiving more transfers per capita, but the effects are concentrated in high-income (typically urban, western) powiats, the mechanism is unclear. The paper's explanation (market thickness) is plausible but creates tension with the first-stage logic. **Required:** Reconcile this by showing that within high-birth-rate powiats, the richer gminas drive the effect, or acknowledge that the treatment intensity measure may be capturing urban economic dynamism rather than transfer exposure.

## 4. Suggestions

**Treatment Construction (Highest Priority):**

The manifest correctly identified that a Bartik-style instrument should combine pre-program household composition shares with national transfer amounts. The current approach—using crude birth rates—misses the actual eligibility structure. Phase I benefits went to (a) all second+ children regardless of income, and (b) first children only below the income threshold. A birth rate captures neither the parity structure nor the income threshold.

*Concrete suggestion:* Use the 2011 National Census (available from GUS) which contains household-level data on number of children by powiat. Construct:
$$\text{Treatment}_{i} = \frac{500 \times 12 \times (\text{Children}_{2+,i} + \text{Children}_{1,i} \times \mathbb{I}[\text{Income}_i < \text{Threshold}])}{\text{Population}_i}$$

For Phase II, the instrument changes because the first-child means test is removed. This gives you two distinct shifters that can be stacked properly. The current single birth-rate measure cannot distinguish Phase I from Phase II variation credibly.

**Statistical Power and Aggregation:**

The manifest confirmed gmina-level data availability (4,198 units) with successful API smoke tests. Aggregating to powiat level (380 units) reduces statistical power by an order of magnitude and masks within-powiat variation that could strengthen identification.

*Concrete suggestion:* Re-run all analyses at the gmina level. This would:
- Increase observations from ~4,900 to ~50,000 powiat-years
- Allow gmina-level clustering with more clusters (though still need to account for powiat-level correlation)
- Enable within-powiat comparisons that control for powiat-specific trends
- Permit analysis of border gminas to test for spatial spillovers (as outlined in the manifest)

If computational constraints require aggregation, at minimum show that gmina-level results are qualitatively similar in a subsample.

**Standard Errors and Inference:**

The 380 clusters are adequate for cluster-robust SEs, but several concerns remain:

1. **Serial correlation:** With 13 years of data and persistent outcomes like business registrations, there may be substantial serial correlation beyond what clustering captures. Consider Conley spatial-HAC standard errors or block bootstrap.

2. **Randomization inference:** The 500 permutations are good, but with continuous treatment, the permutation distribution may not fully capture the null. Consider wild cluster bootstrap-t inference as a complement.

3. **Multiple testing:** Five primary outcomes are tested. The business registration result survives correction, but the unemployment result (p=0.065) becomes marginal. Apply Romano-Wolf or similar corrections and report adjusted p-values.

**Economic Magnitudes:**

The claimed effect (1.94 business registrations per 10K per SD) needs better contextualization:

*Concrete suggestions:*
- What is the survival rate of these new businesses? If they close within 2 years, the economic significance is limited. GUS REGON data includes dissolution dates—use them.
- What sector are these businesses? The manifest proposed testing whether retail/services respond more than manufacturing. This is crucial for the MPC mechanism story.
- Convert to employment effects: If each new business employs X workers on average, what is the implied employment multiplier? This connects to the Nakamura & Steinsson benchmark.
- The unemployment increase (0.30 pp) alongside business formation is puzzling. If plausible, this represents a 2% increase on a 15% baseline. Show this is not driven by registration artifacts (e.g., unemployed mothers registering as job-seekers rather than truly exiting labor force).

**Two-Shock Design:**

The Phase I/Phase II decomposition is the paper's most novel contribution but is implemented problematically. Using the same birth-rate intensity measure for both phases cannot capture the differential exposure—Phase II specifically affected single-child families above the means test, which birth rates don't distinguish.

*Concrete suggestion:* Construct separate intensity measures:
- Phase I intensity: Share of households with 2+ children (universal) + share of single-child households below income threshold
- Phase II intensity: Share of ALL households with children (universal after 2019)

Then estimate:
$$Y_{it} = \alpha_i + \gamma_t + \beta_1 (\text{Intensity}^{I}_i \times \text{Post}^{I}_t) + \beta_2 (\text{Intensity}^{II}_i \times \text{Post}^{II}_t) + \varepsilon_{it}$$

The current specification's negative Phase II birth coefficient (-0.137) is difficult to interpret—universalization should not reduce births in previously high-treatment areas unless there's a composition effect that needs explicit modeling.

**Mechanism Tests:**

The manifest outlined specific mechanism tests that are largely absent:

1. **MPC channel:** Interact treatment with pre-program median income (done) but also with:
   - Share of population in bottom income quintile
   - Average household debt levels (if available from NBP)
   - Retail sales data by powiat (BDL has some commercial activity variables)

2. **Labor supply offset:** The manifest proposed testing whether gmina budgets reduce own social spending. BDL K27 PUBLIC FINANCE has gmina expenditure data—use it to test for crowding out.

3. **Spatial spillovers:** The manifest proposed border powiat analysis. This is important because business registrations in one powiat may reflect demand from neighboring areas. Use a spatial lag model or show that border powiats don't show differential effects.

**Language and Claims:**

Several claims need tempering:

- "Local fiscal multiplier" → "Local economic effects" (unless you calculate an actual multiplier)
- "Randomization inference... confirming the result is not driven by a few influential observations" → RI tests the null of no effect under random assignment, not influence diagnostics
- "The business formation response... creates entrepreneurial opportunities where local markets are already thick" → This is speculation without direct evidence of market thickness mechanisms

*Concrete suggestion:* Add a limitations subsection explicitly acknowledging:
- Treatment intensity is a proxy, not actual transfer amounts
- No powiat-level GDP means no true multiplier estimate
- Aggregate data cannot identify household-level mechanisms (labor supply, consumption)
- Spatial spillovers may bias local effects

**Additional Robustness:**

1. **Alternative pre-periods:** Use 2010-2012 only for treatment construction to ensure longer pre-trend validation.

2. **Leave-one-voivodeship-out:** Show results are not driven by a single region (e.g., Mazowieckie with Warsaw).

3. **Alternative intensity measures:** As the manifest suggested, test share of rural population and share below poverty line as alternative shifters. If these produce similar results, the birth-rate measure may be capturing general economic conditions.

4. **Event-study visualization:** The paper mentions event-study results but doesn't show the figure. Include a coefficient plot with confidence intervals for leads and lags—this is now standard in DiD papers.

5. **First-stage validation:** If possible, correlate the treatment intensity measure with actual 500+ recipient counts from Ministry of Family administrative data (sometimes available through research agreements). This would validate that birth rates proxy actual transfer exposure.

**Writing Improvements:**

- The abstract claims effects "strengthen to 1.9 with voivodeship-by-year fixed effects"—this large change when adding controls should be framed as a concern, not a strength
- Table 1 summary statistics should include treatment intensity variation by voivodeship to show the geographic gradient
- The conclusion's claim that "mailing monthly checks to families is one of the most common things governments do" is rhetorical—tighten to focus on the empirical contribution
- Add a policy implications paragraph: what does this mean for the design of future transfer programs?

**Bottom Line:**

This is a promising paper with a valuable research question and good data access. However, the identification strategy needs substantial strengthening before the causal claims can be supported. The treatment intensity measure is the critical weakness—address this first, then the other issues become more manageable. If the authors can construct a proper Bartik instrument using household composition data and re-run at the gmina level, this could be a strong contribution to both the fiscal multiplier and cash transfer literatures. As currently written, the paper should be framed as exploratory evidence of local economic associations rather than causal multiplier estimates.
