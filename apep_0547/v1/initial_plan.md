# Initial Research Plan: No-Fault Eviction Abolition and Private Rental Supply

## Research Question

Does abolishing no-fault evictions cause landlords to exit the private rental sector, and if so, how does this reshape local housing markets?

## Policy Context

The Renting Homes (Wales) Act 2016 (implemented 1 December 2022) abolished Section 21 no-fault evictions in Wales, replacing them with six-month minimum notice periods under "occupation contracts." Wales was the first UK nation to implement this reform — England's equivalent Renters' Rights Act 2025 has not yet taken effect. All 22 Welsh Local Authorities were treated simultaneously.

## Identification Strategy

**Primary design:** Difference-in-Differences comparing 22 Welsh LAs (treated December 2022) against ~309 English LAs (control), using monthly Land Registry Price Paid transaction data.

**Panel structure:** LA × month, January 2018 – December 2025 (96 months; 48 pre-treatment, 36 post-treatment).

**Estimator:** Callaway-Sant'Anna (2021) — though treatment is simultaneous, CS-DiD handles this cleanly as a single-cohort case. Standard errors clustered at LA level with permutation inference (1,000+ replications) for exact p-values given 22 treated clusters.

**Key assumptions:**
1. Parallel trends in transaction volumes between Welsh and English LAs absent the reform — testable across 48-month pre-period
2. No simultaneous Wales-specific shock in December 2022 other than the Act
3. No anticipation effects prior to implementation date (Act was passed in 2016 but implementation date was set only June 2022)

**Built-in placebos:**
- Owner-occupied properties: unaffected by eviction reform → should show no differential response
- Category A vs Category B transactions: landlord sales more likely classified as Category B (additional properties)
- Property type composition: if landlords exit, we expect relative increases in flats and terraced houses (typical PRS stock)

## Expected Effects and Mechanisms

**Hypothesized mechanism:** Eviction reform increases landlord costs (longer notice periods, fit-for-habitation requirements, reduced flexibility) → marginal landlords sell properties → increased transaction volumes in high-PRS areas of Wales → tenure conversion from rental to owner-occupied.

**Expected signs:**
- Transaction volumes: positive (landlord exit generates sales)
- Category B share: positive (landlord sales are "additional properties")
- Flat/terraced share: positive (PRS stock composition)
- Prices: ambiguous (increased supply depresses prices, but tenure conversion may shift composition toward higher-quality stock)
- Rents: positive (reduced supply → higher rents, if supply effect dominates)

## Primary Specification

$$Y_{it} = \alpha_i + \gamma_t + \beta \cdot (Wales_i \times Post_t) + \epsilon_{it}$$

Where $Y_{it}$ is log transaction count in LA $i$ in month $t$, $Wales_i$ is an indicator for Welsh LAs, $Post_t$ is an indicator for December 2022 onwards, and $\beta$ is the average treatment effect.

**Triple-difference (DDD):** Interact with pre-reform PRS share (from Census 2021) to isolate the landlord-exit channel:

$$Y_{it} = \alpha_i + \gamma_t + \delta \cdot (Wales_i \times Post_t \times PRSShare_i) + \text{controls} + \epsilon_{it}$$

## Exposure Alignment (DiD Requirements)

- **Who is actually treated?** Private landlords in Wales who face new eviction restrictions
- **Primary estimand population:** Housing transactions in Welsh LAs (capturing landlord exit via sales)
- **Placebo/control population:** Owner-occupied transactions (unaffected by eviction reform); English LA transactions (untreated)
- **Design:** DiD (single cohort: all 22 Welsh LAs treated December 2022) with DDD extension using PRS intensity

## Power Assessment

- **Pre-treatment periods:** 48 months (Jan 2018 – Nov 2022)
- **Treated clusters:** 22 Welsh LAs
- **Control clusters:** ~309 English LAs
- **Post-treatment periods:** 36+ months (Dec 2022 – present)
- **MDE:** With 22 treated LAs and 48 pre-periods, estimated MDE of ~8-12% change in transaction volumes at 5% significance

## Planned Robustness Checks

1. **Pre-trend tests:** Event-study with all 48 pre-period coefficients; joint F-test; Rambachan-Roth sensitivity
2. **Border-county subsample:** Restrict English controls to LAs adjacent to Wales (Herefordshire, Shropshire, Gloucestershire, Cheshire West)
3. **Second-home exclusion:** Drop Welsh LAs with high second-home rates (Gwynedd, Ceredigion, Pembrokeshire) to isolate PRS channel from Council Tax Premium effects
4. **Permutation inference:** Randomly assign "treatment" to 22 of 331 LAs, re-estimate 1,000+ times
5. **Leave-one-out:** Drop each Welsh LA in turn to check for influential units
6. **Wild cluster bootstrap:** Alternative inference for clustered standard errors with few treated clusters
7. **Synthetic control:** Match Wales aggregate to weighted English regions as supplementary evidence
8. **Anticipation test:** Restrict pre-period to 2018-2021 (excluding June-November 2022 when implementation date was known)

## Data Sources

| Source | Use | Access |
|--------|-----|--------|
| HM Land Registry PPD | Primary outcome (transactions) | Bulk CSV, no auth |
| ONS NSPL | Postcode → LA mapping | Bulk download |
| Census 2021 (NOMIS) | PRS share by LA, tenure composition | NOMIS API |
| ONS Private Rental Market Statistics | Secondary outcome (rents) | ONS API |
| Rent Smart Wales | Direct rental-supply measure | Public statistics |
| postcodes.io | Postcode geocoding | Free API |
