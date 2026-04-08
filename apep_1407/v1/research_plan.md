# Research Plan: The Insurance Denominator

## Research Question
Does eliminating below-risk flood insurance pricing cause grandfathered policyholders to lapse coverage at higher rates than non-grandfathered policyholders, and what does this reveal about the price elasticity of flood insurance demand?

## Identification Strategy
**Difference-in-Differences** exploiting FEMA's Risk Rating 2.0 (October 1, 2021).

- **Treatment group:** Grandfathered policies (grandfatheringTypeCode = 3) — properties that held continuous NFIP coverage through a prior flood map revision and paid below-risk premiums.
- **Control group:** Non-grandfathered policies (grandfatheringTypeCode = 1) in the same flood zone and county.
- **Shock:** RR2.0 eliminated grandfathering, transitioning all policies to actuarial rates (18% annual cap on increases).
- **AGARA mechanism:** Whether a property was grandfathered depended entirely on the accident of holding continuous coverage at the time of a prior map revision — orthogonal to current flood risk or owner characteristics.

## Expected Effects and Mechanisms
1. **Premium increase:** Grandfathered properties should see disproportionate premium increases post-RR2.0 (first stage).
2. **Policy lapse:** Higher premiums → higher lapse rates among grandfathered policies, especially for non-mandatory (voluntary) policies.
3. **Coverage reduction:** Properties that maintain coverage may reduce coverage amounts (building insurance / replacement cost ratio).
4. **Heterogeneity:** Mandatory-purchase (SFHA with mortgage) vs voluntary policies; primary residence vs investment properties.

## Primary Specification
$$Y_{it} = \alpha + \beta \cdot \text{Grandfathered}_i \times \text{Post}_{t} + \gamma_i + \delta_t + X_{it}\theta + \varepsilon_{it}$$

Where $Y_{it}$ is {premium, lapse indicator, coverage ratio}, with policy fixed effects $\gamma_i$ and year-quarter fixed effects $\delta_t$. Cluster standard errors at the county level.

## Data Source and Fetch Strategy
1. **OpenFEMA FimaNfipPolicies** — 72.6M records. API endpoint: `https://www.fema.gov/api/open/v2/FimaNfipPolicies`. Key fields: grandfatheringTypeCode, totalInsurancePremiumOfThePolicy, policyEffectiveDate, cancellationDateOfFloodPolicy, floodZoneCurrent, ratedFloodZone, propertyState, countyCode, mandatoryPurchaseFlag, primaryResidenceIndicator, totalBuildingInsuranceCoverage.

2. **Strategy for 72.6M records:** Use API filters to download policy-year cohorts. Focus on policies effective 2019-2024 to get adequate pre/post periods. Filter by high-volume states (FL, TX, LA, NJ, NY) for tractability, then expand.

3. **OpenFEMA NfipResidentialPenetrationRates** — 3,158 county records for cross-sectional context.

## Key Robustness
- Placebo: X-zone (non-SFHA) properties should show no differential response
- Event study: quarterly coefficients pre/post Oct 2021
- Dose-response: treatment intensity = magnitude of implied grandfathered discount
- Heterogeneity: mandatory vs voluntary, primary vs investment, coastal vs inland
