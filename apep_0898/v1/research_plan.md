# Research Plan: The Domino Effect — Grocery Exits Trigger Cascading Business Closures

## Research Question

Does the exit of a grocery anchor store cause cascading closures of neighboring businesses? We test the anchor-tenant externality hypothesis at national scale using corporate chain bankruptcy events as supply-side shocks.

## Identification Strategy

**Design**: Bartik/shift-share instrumental variables with staggered timing.

**Treatment**: County-year grocery establishment losses, measured via Census CBP NAICS 445 (food and beverage stores).

**Instrument**: National chain bankruptcy events × county-level pre-period chain exposure (shift-share). Major chain bankruptcies (Winn-Dixie 2005, A&P 2010/2015, Marsh 2017, Tops 2018, Southeastern Grocers 2018, Earth Fare 2020, Lucky's Market 2020) provide plausibly exogenous supply-side shocks. Pre-period county share of state-level grocery establishments proxies for chain exposure.

**Key assumption**: National chain bankruptcy decisions are driven by corporate financial distress, not by local economic conditions in any single county. The exclusion restriction requires that chain bankruptcies affect local non-grocery businesses only through the grocery exit channel.

## Expected Effects and Mechanisms

- **Direct effect**: Grocery exit reduces foot traffic to neighboring retail locations
- **Cascade mechanism**: Reduced foot traffic → lower revenue for adjacent stores → closures in food service (NAICS 722), health/personal care (446), and general retail (44-45 ex-grocery)
- **Poverty trap**: Loss of complementary ecosystem may prevent anchor replacement
- **Heterogeneity**: Effects should be larger in counties with fewer grocery alternatives (higher HHI) and in rural/small metro counties

## Primary Specification

**Reduced form (staggered DiD)**:
Y_{ct} = α_c + δ_t + β × GroceryExit_{ct} + X_{ct}γ + ε_{ct}

Where GroceryExit_{ct} = 1 if county c experiences ≥20% decline in NAICS 445 establishments in year t.

**IV (2SLS)**:
First stage: GroceryExit_{ct} = α_c + δ_t + π × BartikExposure_{ct} + X_{ct}γ + ν_{ct}

Where BartikExposure_{ct} = Σ_k 1[chain_k in state(c)] × (grocery_estab_{c,base} / grocery_estab_{state(c),base}) × 1[bankruptcy_k ≤ t]

**Robust DiD**: Callaway-Sant'Anna for staggered adoption (avoid TWFE bias).

**Clustering**: State level (bankruptcy exposure is at state level).

## Data Sources

1. **Census County Business Patterns (CBP)**: County × NAICS establishment counts and employment, 2005-2022. Census API with key.
2. **Census Business Dynamics Statistics (BDS)**: County-level firm births, deaths, entry/exit rates. Downloadable CSV.
3. **Chain bankruptcy events**: Compiled from public records (SEC filings, news archives).
4. **USDA SNAP Retailers**: Current store locations with chain names for validation.

## Fetch Strategy

1. CBP: Census API calls for NAICS 445 (grocery), 44-45 (retail), 722 (food service), 446 (health/personal care), 812 (personal services) at county level, 2005-2022.
2. BDS: Download county-level CSV from Census website.
3. Chain bankruptcies: Hard-code from public knowledge (no API needed).
4. SNAP: USDA SNAP Store Locator API for current chain presence validation.
