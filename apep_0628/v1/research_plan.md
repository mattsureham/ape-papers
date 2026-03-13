# Research Plan: The Invisible Tariff — Nigeria's FX Exclusion List and Product-Level Trade Destruction

## Research Question

Does restricting access to official foreign exchange for specific product categories function as an invisible tariff, destroying imports and raising domestic prices? We study Nigeria's June 2015 CBN circular that banned 41 product categories from accessing official FX, forcing importers to source dollars on the parallel market at a 30-60% premium.

## Policy Background

On June 23, 2015, the Central Bank of Nigeria (CBN) issued circular TED/FEM/FPC/GEN/01/011, designating 41 product categories as "not valid for foreign exchange" in the Nigerian FX market. Key banned categories include rice, cement, steel, textiles, margarine, palm kernel oil, and private jets. Importers could still import these items but had to source dollars from the parallel market, where the naira traded at a significant premium (30-60% above the official rate by 2016-2017). The list expanded to 43 items by 2020 and was lifted on October 12, 2023.

This policy is economically equivalent to a selective tariff equal to the parallel market premium — but entirely opaque, administered through the banking system rather than customs. Many developing countries use similar FX restrictions as de facto trade barriers. Nigeria provides the cleanest setting for causal estimation.

## Identification Strategy

### Primary: Product-Level DiD

Compare imports of FX-banned HS6 product codes (~150-200 codes) vs non-banned HS6 codes (~4,800 codes), before (2012-2014) vs after (2016-2022) the June 2015 ban.

Y_{p,t} = α_p + γ_t + β(Banned_p × Post_t) + ε_{p,t}

where Y is log import value (USD), α_p are product FE, γ_t are year FE.

### DDD with Country Controls

Compare banned vs non-banned product imports into Nigeria vs imports of the same products into Ghana, Côte d'Ivoire, and Senegal (no FX restrictions).

Y_{p,c,t} = α_{p,c} + γ_{c,t} + δ_{p,t} + β(Banned_p × Nigeria_c × Post_t) + ε_{p,c,t}

This absorbs product-specific global trade trends and country-specific shocks.

### Mechanism Tests

1. **Domestic substitution**: Did Nigerian domestic production of banned items (rice, cement) increase? FAO production data.
2. **FX premium channel**: Time-varying treatment intensity using parallel market premium.
3. **Trade diversion**: Did neighboring countries' imports of banned products increase (re-export to Nigeria)?

### Placebo Tests

1. Non-banned products should show no differential decline
2. Banned products should show no differential decline in control countries
3. Pre-2015 pseudo-treatment dates should yield null effects

## Data Sources

1. **UN Comtrade API** (primary): Bilateral trade at HS6 level, annual. Nigeria + Ghana + Côte d'Ivoire + Senegal as importers, all partner countries. Years 2012-2022. API key available.

2. **CBN circular TED/FEM/FPC/GEN/01/011**: Official list of 41 banned product categories, mapped to HS6 codes.

3. **Parallel market FX rates**: For mechanism analysis (treatment intensity over time).

## Primary Specification

Event study with product and year FE:

Y_{p,t} = α_p + γ_t + Σ_k β_k(Banned_p × 1{t=k}) + ε_{p,t}

with standard errors clustered at the HS2 chapter level (to account for within-chapter correlation of trade shocks).

## Expected Effects

- Large decline in imports of banned products (β < 0), magnitude proportional to the parallel market premium
- Potentially offset by domestic production increases for substitutable goods
- Trade diversion to neighboring countries for goods re-exported to Nigeria

## Risk Assessment

- **Data availability**: Comtrade API confirmed working for Nigeria HS data. Key risk is coverage gaps in specific years.
- **HS code mapping**: The CBN circular uses product category names, not HS codes. Mapping to HS6 requires careful concordance.
- **Concurrent shocks**: Oil price collapse (2014-2016) affects Nigeria broadly but should not differentially affect banned vs non-banned products.
- **Pre-trends**: If banned products were already declining before the ban (e.g., due to import substitution policies), the DiD estimate is biased.
