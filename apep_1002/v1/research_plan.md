# Research Plan: apep_1002

## Research Question
Does formalization persist after digital enforcement is removed? The Czech Republic's January 2023 abolition of its Electronic Sales Registration (EET) system — after mandating real-time cash transaction reporting since December 2016 — is the first known case of a developed country voluntarily dismantling a functioning digital tax enforcement system. If formalization is "sticky," we should observe no reversal in business registrations after abolition. If "elastic," we should see a surge in new registrations as previously formalized businesses re-enter the shadow economy or new informal entrants emerge.

## Named Mechanism: The Compliance Ratchet
The paper tests whether digital enforcement creates a **compliance ratchet** — a one-way mechanism where formalization gains persist even after the enforcement lever is removed. This has never been tested because no country has previously reversed enforcement.

## Identification Strategy

### Primary: Cross-Country Difference-in-Differences
- **Treated**: Czech Republic (abolished EET January 1, 2023)
- **Controls**: Hungary, Croatia, Italy, Poland, Sweden — all maintained fiscal enforcement systems
- **Pre-period**: Q1 2015 – Q4 2022 (32 quarters)
- **Post-period**: Q1 2023 – Q4 2025 (12 quarters)
- **Outcome**: Eurostat STS_RB_Q quarterly business registration indices by NACE sector

### Secondary: Within-Czech Sectoral Variation
EET was introduced in four staggered phases:
- Phase 1 (Dec 2016): Accommodation/food services
- Phase 2 (Mar 2017): Wholesale/retail
- Phase 3 (Mar 2018): Professional services/transport
- Phase 4 (Jun 2018): Crafts/production

All sectors were simultaneously "un-treated" on January 1, 2023. If formalization is elastic, Phase 1 sectors (longest exposure, most cash-intensive) should show the largest post-abolition response.

## Expected Effects
- **If compliance ratchet holds**: Null effect — business registrations in CZ should track control countries after abolition
- **If formalization is elastic**: Positive effect — CZ registrations surge relative to controls, especially in cash-intensive sectors (accommodation, food services, retail)
- **Smoke test**: CZ accommodation registrations jumped from 93.7 to 131.6 (+40%) in Q1 2023; no comparable jump in controls → suggests ratchet does NOT hold

## Data Sources
1. **Eurostat STS_RB_Q**: Quarterly business registration indices (2015-2025), by country and NACE sector. SDMX API, no auth required.
2. **Eurostat GOV_10A_TAXAG**: VAT revenue as % of GDP (2010-2024). Cross-country fiscal impact.
3. **Eurostat BD_9BD_SZ_CL_R2**: Annual business demography (births, deaths, 2004-2020). Pre-treatment validation.

All accessed via `eurostat` R package or direct SDMX REST API.

## Primary Specification
```
Y_{ist} = α + β * Post_t * Czech_i + γ_i + δ_t + ε_{ist}
```
Where Y is business registration index for country i, sector s, quarter t. Post = 1 for Q1 2023+, Czech = 1 for Czech Republic. Country and quarter fixed effects. Standard errors clustered at country level (with wild cluster bootstrap given small number of clusters).

## Robustness
1. Wild cluster bootstrap inference (6 clusters)
2. Synthetic control method (CZ vs. weighted donor pool)
3. Placebo test: pre-existing trends using Q1 2020 (COVID) as fake treatment date
4. Leave-one-out: drop each control country
5. Event study: quarterly treatment leads/lags
6. Cross-sector heterogeneity: cash-intensive vs. non-cash sectors

## Key Risk
Small number of country-level clusters (6). Will address with wild cluster bootstrap and randomization inference. The within-Czech sectoral design provides additional identifying variation.
