# Initial Research Plan — apep_0505

## Title
The Hidden Costs of Devolved Austerity: Council Tax Support Localization and Household Distress in England

## Research Question
Did the 2013 localization of Council Tax Support — which shifted responsibility for low-income council tax relief from the national government to 326 English Local Authorities — generate hidden social costs that offset the fiscal savings from devolution?

## Policy Background
In April 2013, the UK government abolished the nationally uniform Council Tax Benefit (CTB) and replaced it with locally designed Council Tax Support (CTS) schemes. The reform had three key features:
1. **Budget cut:** National funding was reduced by approximately 10% (£500M).
2. **Local discretion:** Each LA chose how to allocate the cut — via minimum payment rates (0% to 30%+), band caps, income tapers, or other scheme parameters.
3. **Pensioner protection:** By law, pension-age claimants retained identical entitlements to the old national CTB. Working-age claimants bore the entire adjustment.

The reform affected approximately 2.4 million working-age households in England. LAs that imposed higher minimum payment rates generated new tax bills of £100-400+ per year for their poorest working-age residents.

## Identification Strategy
**Continuous-treatment Difference-in-Differences:**

Y_{lt} = alpha_l + gamma_t + beta(TreatmentIntensity_l x Post_t) + X_{lt}'delta + epsilon_{lt}

- **Y_{lt}:** Outcome for LA l at time t
- **alpha_l:** LA fixed effects
- **gamma_t:** Year fixed effects
- **TreatmentIntensity_l:** Change in CTS expenditure per working-age claimant from 2012/13 to 2013/14 (continuous, varies across LAs based on scheme generosity)
- **Post_t:** Indicator for t >= April 2013
- **X_{lt}:** Time-varying controls (total LA revenue expenditure per capita, Revenue Support Grant, Index of Multiple Deprivation quintile interactions)
- **Clustering:** LA level (326 clusters)

**Key identifying assumption:** LAs that chose less generous CTS schemes would have followed similar outcome trends to LAs that chose more generous schemes, absent the differential policy treatment.

**Why this is credible:**
1. Pre-2013, CTB was nationally uniform — no policy-driven variation existed, so pre-trends reflect only secular differences.
2. The reform was imposed by central government; LAs did not choose WHETHER to reform, only HOW MUCH to cut.
3. The pensioner placebo group (exempt from any changes) provides within-LA falsification.

## Exposure Alignment (DiD Requirements)
- **Who is actually treated?** Working-age Council Tax Support claimants in LAs that imposed minimum payments >0%.
- **Primary estimand population:** LA-level outcomes (collection rates, arrears, crime, property prices) in working-age-affected areas.
- **Placebo/control population:** Pensioner CTS claimants (exempt by law) in the same LAs.
- **Design:** Continuous-treatment DiD (all LAs "treated" simultaneously in April 2013, but with varying dosage based on minimum payment rate).

## Power Assessment
- **Pre-treatment periods:** 5 years (2008/09 to 2012/13) for fiscal outcomes, 2 years (2011-2013) for crime
- **Treated clusters:** 326 English LAs (approximately 230 imposed minimum payments >0%)
- **Post-treatment periods:** 11 years (2013/14 to 2023/24)
- **MDE estimate:** With 326 clusters, 16 time periods, and ICC ~0.5, MDE is approximately 0.05 SD for collection rates — well below plausible effects.

## Expected Effects and Mechanisms
1. **Collection rates should fall** in high-minimum-payment LAs (IFS found ~25% of new tax uncollectable).
2. **Arrears should rise** as households unable to pay accumulate Council Tax debt.
3. **Crime may increase** through financial stress channel (property crime, shoplifting, domestic violence).
4. **Property prices may decline** if higher CT burden reduces area attractiveness to low-income households, or increase if reduced social housing demand tightens private market.

## Primary Specification
Event study with year-by-year interactions:

Y_{lt} = alpha_l + gamma_t + sum_{k != 2012/13} beta_k (TreatmentIntensity_l x Year_k) + X_{lt}'delta + epsilon_{lt}

Plotting beta_k coefficients for k = 2008/09, ..., 2023/24 (normalized to zero at 2012/13).

## Planned Robustness Checks
1. **Pensioner placebo:** Same specification with pensioner outcomes — should show zero effects.
2. **Negative control outcomes:** Business rate collection, parking revenue — should be unaffected.
3. **Alternative treatment measures:** Binary (any minimum payment >0%), categorical (0%, 1-10%, 11-20%, 21%+), and continuous (minimum payment rate from IFS data).
4. **Excluding London:** London boroughs face unique fiscal pressures.
5. **COVID robustness:** Separate pre-COVID (2013-2019) and full-period (2013-2024) estimates.
6. **HonestDiD sensitivity:** Rambachan-Roth bounds for violations of parallel trends.
7. **Wild cluster bootstrap:** Given 326 clusters is large but not huge, verify inference.

## Data Sources
| Variable | Source | Granularity | Years |
|----------|--------|-------------|-------|
| CTS/CTB expenditure & caseloads | DLUHC/DWP statistics (gov.uk) | LA × year | 2008-2024 |
| Council Tax collection rates | DLUHC QRC4/statistics (gov.uk) | LA × year | 2008-2024 |
| Council Tax Band D levels | DLUHC live tables (gov.uk) | LA × year | 2008-2024 |
| Property prices | HM Land Registry PPD (S3 bulk CSV) | Transaction-level | 2008-2024 |
| Crime | data.police.uk archives (monthly CSV) | LSOA/LA × month | 2011-2024 |
| Claimant counts | NOMIS API | LA × month | 2008-2024 |
| LA revenue expenditure | DLUHC Revenue Outturn (gov.uk) | LA × year | 2008-2024 |

## Key Risks
1. **Data risk:** Minimum payment rate data may require extraction from IFS appendix or construction from expenditure ratios.
2. **Identification risk:** LAs' scheme choices are endogenous to local conditions. Mitigation: pensioner placebo, pre-trend validation, controls for broader austerity.
3. **Confounding risk:** CTS reform coincided with other welfare reforms (benefit cap, bedroom tax, Universal Credit rollout). Mitigation: control for concurrent reform exposure; pensioner placebo absorbs LA-level shocks.
