# V1 Empirics Check — mistralai/mistral-large-2512 (Variant A)

**Model:** mistralai/mistral-large-2512
**Variant:** A
**Date:** 2026-04-02T22:57:50.631247

---

### 1. Idea Fidelity

The paper closely adheres to the original idea manifest, successfully executing the proposed identification strategy and empirical approach. Key elements from the manifest are preserved:

- **Identification Strategy**: The paper correctly implements a staggered difference-in-differences (DiD) design using the Callaway & Sant’Anna (2021) estimator, leveraging the exogenous timing of lottery-allocated dispensary openings across counties. The use of not-yet-treated counties as controls within BLS regions is consistent with the manifest’s plan.
- **Data Sources**: The paper uses the promised data sources: Census QWI for employment/earnings (county-quarter-industry level) and IDFPR dispensary license records. The manifest’s "smoke test" API calls are mirrored in the paper’s data appendix.
- **Research Question**: The paper tests whether randomized dispensary entry generates local economic gains, with a focus on employment spillovers. The social equity angle is acknowledged, though the paper rightly notes that the design cannot distinguish effects by licensee type (social equity vs. others).
- **Novelty**: The paper delivers on the manifest’s claim of novelty, as the first study of Illinois’s cannabis dispensary lotteries and their economic effects (prior work focused on crime or cross-state comparisons).

**Minor Deviations**:
- The manifest proposed analyzing earnings and business formation, but the paper focuses on employment and earnings (business formation is not addressed). This is a reasonable narrowing given data constraints.
- The manifest suggested tract-level analysis, but the paper uses county-level data. This is justified by the manifest’s own feasibility check (county-level QWI data is confirmed), but the paper should acknowledge the trade-off in spatial granularity.

### 2. Summary

This paper exploits Illinois’s randomized cannabis dispensary license lotteries (2021–2023) to estimate the local employment effects of new dispensaries. Using a staggered DiD design with Census QWI data, the authors find that lottery-allocated dispensaries increase food service employment by 2.2% (a "foot traffic dividend") but have no detectable effects on retail employment, total employment, or earnings. The results are robust to placebo tests and alternative specifications, suggesting that dispensaries generate narrow consumption spillovers rather than broad economic renewal. The paper contributes to literatures on cannabis legalization, retail spillovers, and social equity licensing.

### 3. Essential Points

**1. Treatment Definition and Timing**
The paper defines treatment as the quarter of the first lottery-allocated dispensary opening, with a two-quarter lag from license issuance to account for buildout. This is a reasonable approximation, but the paper must address two concerns:
   - **Measurement Error**: The lag is uniform, but buildout times likely vary (e.g., urban vs. rural counties). The authors should test sensitivity to alternative lags (e.g., 1 or 3 quarters) or use actual opening dates if available (e.g., from state inspections or business filings).
   - **Pre-Existing Dispensaries**: Some counties had pre-existing (non-lottery) dispensaries. The paper controls for this in robustness checks, but the main specification should include a count of pre-existing dispensaries as a covariate to absorb baseline differences in cannabis market activity.

**2. Spatial Scale and General Equilibrium Effects**
The county-level analysis may dilute hyper-local effects (e.g., block-level spillovers) and miss general equilibrium effects (e.g., labor market competition). The authors should:
   - **Acknowledge the Limitation**: Explicitly state that the null results for retail/total employment could reflect spatial aggregation bias. If tract-level QWI data is unavailable, discuss whether block-level data (e.g., LEHD Origin-Destination Employment Statistics) could be used in future work.
   - **Test for Spillovers**: Check whether treated counties’ neighbors (e.g., adjacent counties) experience employment changes, which would suggest cross-county spillovers or displacement.

**3. Social Equity Angle**
The manifest emphasizes the social equity component of Illinois’s lotteries, but the paper does not distinguish between social equity and non-equity licensees. This is a missed opportunity:
   - **Heterogeneity Analysis**: Test whether effects differ for counties receiving social equity vs. non-equity lottery dispensaries. If data is unavailable, discuss whether social equity licensees might differ in business models (e.g., smaller scale, community-focused) that could affect spillovers.
   - **Policy Implications**: The discussion should clarify that the results speak to the average effect of lottery dispensaries, not the specific impact of social equity licensing. The paper’s conclusion ("calibrating expectations") is appropriate but could be sharpened by noting that social equity programs may still achieve wealth-building goals even if employment effects are limited.

### 4. Suggestions

**A. Data and Measurement**
1. **Opening Dates**: If possible, collect actual dispensary opening dates (e.g., from state inspections, business filings, or web scraping) to replace the two-quarter lag. This would reduce measurement error and improve precision.
2. **Cannabis-Specific Employment**: The QWI does not separately tabulate cannabis employment (NAICS 453998). If dispensary employment data is available (e.g., from state labor agencies or surveys), include it as an outcome to measure direct job creation.
3. **Tax Revenue Data**: The paper mentions tax revenue but does not analyze it. BEA or state revenue data could be used to test whether dispensaries generate fiscal spillovers (e.g., increased local government spending).
4. **Business Formation**: The manifest proposed analyzing business formation. While county-level data may lack power, the authors could use Census Business Dynamics Statistics (BDS) or state business registration data to test for new firm entry in treated counties.

**B. Empirical Strategy**
1. **Covariate Adjustment**: The main specification includes no covariates. While the lottery is random, adjusting for pre-treatment covariates (e.g., pre-existing dispensaries, county population, unemployment rate) could improve precision. The authors should report results with and without covariates.
2. **Alternative Comparison Groups**: The paper uses not-yet-treated counties as controls. Also test:
   - **Never-Treated Counties**: As in the robustness checks, but for all outcomes.
   - **Synthetic Controls**: Construct synthetic control groups for treated counties to address concerns about parallel trends.
3. **Heterogeneity by County Size**: The paper finds larger effects in big counties. Explore additional heterogeneity by:
   - Urban/rural status (e.g., using USDA Rural-Urban Continuum Codes).
   - Pre-treatment employment density (e.g., retail/food service employment per capita).
4. **Dynamic Effects**: The event study shows persistent effects for food service employment. Test whether effects fade over time (e.g., by estimating separate ATTs for short- vs. long-run horizons).

**C. Interpretation and Discussion**
1. **Mechanisms**: The paper speculates about mechanisms (substitution, capital intensity) but could strengthen this with:
   - **Wage Effects**: Test whether food service wages increase in treated counties, which would support a demand-driven mechanism.
   - **Retail Sales Data**: If available, use Census Retail Trade data to test whether dispensaries crowd out other retail spending.
2. **External Validity**: Discuss whether Illinois’s results generalize to other states with different regulatory regimes (e.g., merit-based licensing, lower taxes) or market structures (e.g., fewer pre-existing dispensaries).
3. **Policy Implications**: The paper’s conclusion is cautious, but policymakers may overinterpret the null results. Clarify:
   - The limitations of county-level analysis (e.g., hyper-local effects may exist).
   - That social equity programs may still achieve goals beyond employment (e.g., wealth building, criminal justice reform).
4. **Placebo Outcomes**: The manufacturing placebo is strong. Also test:
   - **Unrelated Sectors**: E.g., healthcare (NAICS 62) or construction (NAICS 23).
   - **Geographic Placebos**: Test whether treated counties’ neighbors experience effects (to rule out spillovers).

**D. Presentation and Clarity**
1. **Figures**: The paper relies heavily on tables. Add:
   - A map of treated vs. control counties to visualize geographic variation.
   - Event-study plots for all outcomes (not just food service) to show pre-trends.
2. **Standardized Effects**: The standardized effect sizes (Appendix Table 1) are helpful. Also report:
   - **Economic Magnitudes**: Translate the 2.2% food service effect into jobs (e.g., "equivalent to X jobs per dispensary").
   - **Confidence Intervals**: For null results, emphasize the bounds (e.g., "we can rule out effects larger than 1.2%").
3. **Robustness Appendix**: Move robustness checks (e.g., alternative lags, comparison groups) to an appendix to streamline the main text.
4. **Clarity on Lottery Randomness**: The paper states the lottery is "genuinely random," but the manifest notes applicants must meet an 85% scoring threshold. Clarify that randomness is conditional on eligibility, and discuss whether this could induce selection (e.g., if high-scoring applicants are more likely to open in high-growth areas).

**E. Minor Issues**
1. **Pre-Treatment Period**: The pre-period includes COVID-19 (2020Q2–Q3). While fixed effects absorb aggregate shocks, the authors should discuss whether county-specific recovery patterns could confound the results.
2. **Multiple Testing**: The paper tests multiple outcomes. Consider adjusting p-values for multiple comparisons (e.g., Bonferroni correction) or emphasizing the food service result as the primary outcome.
3. **JEL Codes**: Add R58 (Regional Development Planning and Policy) to reflect the place-based focus.

### Final Assessment
This is a well-executed paper with a credible identification strategy and clear contributions. The essential points above are addressable with additional robustness checks and clarifications. The paper’s strengths—exogenous variation, careful event-study analysis, and policy relevance—outweigh its limitations. With revisions, it would be suitable for publication in a journal like *AER: Insights*.
