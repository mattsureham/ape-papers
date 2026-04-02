# Research Plan: Ghana's Great Microfinance Purge

## Research Question
What is the causal effect of sudden, large-scale financial intermediary destruction on local economic activity in a developing country?

## Setting
On May 31, 2019, the Bank of Ghana (BoG) revoked 347 microfinance company licenses (192 insolvent + 155 ceased operations). On August 16, 2019, 23 savings-and-loans/finance house licenses were revoked. This was the largest mass revocation of financial institution licenses in Sub-Saharan African history.

The revocations were geographically concentrated: Ashanti and Greater Accra regions had the highest MFI density, while Northern Ghana had minimal presence.

## Identification Strategy
**Dose-response DiD.** Treatment intensity = number of revoked MFIs per 100,000 district population. Higher-exposure districts (primarily Ashanti, Greater Accra, Western, Eastern regions) serve as treated; lower-exposure districts (Northern, Upper East, Upper West, Savannah) serve as controls.

- **Key assumption:** Parallel pre-trends in nighttime lights across high- vs. low-MFI-density districts
- **Pre-period:** January 2014 -- April 2019 (~64 months)
- **Treatment date:** May 2019
- **Post-period:** June 2019 -- December 2023 (~55 months)
- **Estimator:** Continuous treatment DiD via `fixest::feols()` with district + month FE, clustering at district level

## Expected Effects and Mechanisms
- **Primary hypothesis:** Districts with higher MFI revocation intensity experience larger declines in nighttime light intensity (proxy for economic activity)
- **Mechanism 1 (Credit contraction):** Sudden loss of credit access reduces small business activity
- **Mechanism 2 (Substitution):** Mobile money and formal banking may partially offset
- **Mechanism 3 (Confidence shock):** Even solvent institutions face depositor runs

## Primary Specification
$$Y_{dt} = \alpha_d + \gamma_t + \beta \cdot (Intensity_d \times Post_t) + \varepsilon_{dt}$$

Where:
- $Y_{dt}$: Log mean nighttime radiance in district $d$, month $t$
- $\alpha_d$: District fixed effects
- $\gamma_t$: Year-month fixed effects
- $Intensity_d$: Pre-determined MFI revocation intensity (revoked MFIs per 100k population)
- $Post_t$: Indicator for $t \geq$ June 2019

## Data Sources

### Primary outcome: VIIRS Nighttime Lights
- Source: NASA Black Marble VNP46A4 monthly composites (via `blackmarbler` R package)
- Resolution: 500m, aggregated to district level
- Period: 2014--2023
- Bearer token: NASA Earthdata (available in .env as NASA_EARTH)

### Treatment variable: MFI Revocation List
- Source: Bank of Ghana press releases (May 31, 2019; August 16, 2019)
- Contains: Full list of 347+23 entity names with registered offices
- Geocoding: Extract location from company names + BoG regional data
- Fallback: Use BoG Annual Report regional MFI counts, distributed to districts proportionally

### Geography: District Boundaries
- Source: GADM v4.1 (Ghana admin level 2 = districts)
- Via `geodata::gadm()` R package
- ~260 districts

### District Population
- Source: Ghana Statistical Service (2021 Population and Housing Census)
- Via Ghana Open Data or WorldPop gridded population

## Robustness Checks
1. Event study: coefficients for each quarter pre/post
2. Placebo treatment date (2017)
3. Permutation inference (randomize treatment intensity across districts)
4. Alternative outcome: annual VIIRS instead of monthly
5. Exclude Accra Metro (largest city, potential outlier)
6. Binary treatment (above/below median MFI density)
